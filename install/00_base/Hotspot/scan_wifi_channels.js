let log = () => {};
try {
    const debug = require('debug'); // if we have it
    log = debug('scan-wifi-channels');
} catch(e) {}

const { execSync } = require('child_process');
const input = execSync('iwlist wlan0 scan').toString('utf-8');
const lines = input.split('\n');
const stations = [];

// Parse lines from iwlist with regex & save results in stations
let current = null;
for (const line of lines) {
    let result = line.match(/Cell (?<cell>\d+)\s*-\s*Address:\s*(?<mac>[0-9A-F:]{17})/i);
    if (result) {
        if (current !== null) {
            stations.push(current);
        }
        current = {
            cell: result.groups.cell,
            mac: result.groups.mac,
        };
        continue;
    }
    result = line.match(/Frequency:\s*(?<frequency>\S+)|Channel:\s*(?<channel>\d+)|Quality=(?<quality>\S+)\s*Signal level=(?<level>\S+)\s*dBm/i);
    if (result) {
        for (let [key, value] of Object.entries(result.groups)) {
            current[key] = current[key] || value;
        }
        //log(result);
    }
}
if (current !== null) {
    stations.push(current);
}

// Now we look at channel usage and try to pick a quiet/available one.
// 2.4GHz channels 1-11 are allowed in North America, Japan, and "Most of world" so we'll choose one of those
// See https://en.wikipedia.org/wiki/List_of_WLAN_channels#2.4_GHz_(802.11b/g/n/ax)
const survey = new Array(11).fill(null).map((_, i) => ({ channel: i+1, maxStrength: 0, numStations: 0 }));

for (const station of stations) {
    if (typeof station.quality === 'string') {
        station.strength = station.quality.split('/').map(x => parseInt(x, 10)).reduce((x, y) => x/y);
    }
    if (station.channel) {
        station.channel = parseInt(station.channel, 10);
        const group = survey.find(g => g.channel === station.channel);
        if (!group) {
            log(`Ignoring station on ignored channel (${station.channel})`, station);
            continue;
        }
        group.numStations += 1;
        if (station.strength > group.maxStrength) {
            group.maxStrength = station.strength;
        }
    }
}

// In case there are ties (e.g. multiple apparently unused channels) we'd like to favor those that
// are not adjacent to strong signals, so we compute a score for each that is a weighted average:
// 80%*(1/stength) + 20%(1/neighbor_strength)
// After that, we'll break ties by lowest channel number
for (let i=0; i<survey.length; i++) {
    let weighted;
    if (i === 0) {
        weighted = 0.8 * survey[i].maxStrength + 0.2 * survey[i+1].maxStrength;
    } else if(i === survey.length - 1) {
        weighted = 0.8 * survey[i].maxStrength + 0.2 * survey[i-1].maxStrength;
    } else {
        weighted = 0.8 * survey[i].maxStrength +
            0.1 * survey[i-1].maxStrength
        0.1 * survey[i+1].maxStrength;
    }
    survey[i].weightedStrength = weighted;
}
log(stations, survey);
const lowest = Math.min(...survey.map(s => s.weightedStrength));
const winner = survey.find(s => s.weightedStrength === lowest);
log(`Winner:`, winner);

console.log(winner.channel); // program output (not debug info)
