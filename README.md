# "TimeBerry64-trixie-rasp4"

## Script d'installation rapide de Volumio sur Raspberry Pi 4

### Note de projet - v0.0.2 : TODO

Adapter l'installation à Github : - changer les chemins d'accès pour en faire des références internes dans les dossiers. Soit ../../.. au besoin.


### Note de projet - v0.0.1:

Attention il y a (avait?) une erreur dans le script des services bluealsa & ba-aplay.
L'appel des options est fautif du fait du caractère d'échappement \$OPTION

#### Note au 23 août 2022
> Ces fichiers sont créés via une commande *cat* plutôt qu'une copie d'un fichier existant. Après essais, il FAUT mettre des caractères d'échappements devant certains caractères. Que ça soit sous bash ou sous sh. L'erreur devait provenir du fait que j'avais fait un copier-coller du document plutôt que d'utiliser directement le script/

> Script selon syntaxe sh + sh appelé par le fichier + lancé directement.
- l'échappement se fait correctement
- s'il n'y a pas d'échappement la valeur $OPTIONS est cherchée - donc omise.

> Idem - avec sudo : même résultat

> Script inchangé mais appel bash + lancé directement.
- l'échappement se fait correctement ???
- et fonctionne de la même façon qu'avec un appel sh

> Appel bash manuel
- OK idem ???}
