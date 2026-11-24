# Ajout du copier-coller au package BGInfo

Ce dossier est un **patch à ajouter au package existant**, pas le package BGInfo complet. Il contient le lanceur et un script PowerShell adapté aux champs de `bginfo.bgi`.

## Fichiers à ajouter au dossier source du package

Copier dans le dossier où se trouvent déjà `bginfo.bgi`, `Bginfo64.exe` et `Information Session Utilisateur.lnk` :

- `Lancer-Information.cmd`
- `Copier-BGInfo.ps1`

Le lanceur utilise les noms `Bginfo64.exe` et `bginfo.bgi`; adapter ces noms s'ils diffèrent.

## Raccourci

Modifier le raccourci source `Information Session Utilisateur.lnk` avant le déploiement :

- **Cible** : `C:\Program Files (x86)\Sysinternals\BGInfo\Lancer-Information.cmd`
- **Démarrer dans** : `C:\Program Files (x86)\Sysinternals\BGInfo`

Le script d'installation copie ensuite le raccourci vers le Bureau public.

## Fonctionnement

Le lanceur démarre la popup BGInfo sans attendre sa fermeture. En parallèle, `Copier-BGInfo.ps1` récupère les champs affichés dans la configuration à partir des mêmes sources WMI et registre indiquées dans le `.bgi`, puis met un rapport texte dans le presse-papiers. L'utilisateur peut coller avec **Ctrl+V** pendant que la popup reste ouverte.

Le rapport reprend les champs et les sources configurés, mais sa mise en forme peut différer légèrement de celle de la fenêtre BGInfo. Le script doit s'exécuter dans la session interactive de l'utilisateur pour accéder à son presse-papiers. Si l'entreprise impose des scripts PowerShell signés, faire signer ce `.ps1` par le certificat de l'entreprise.

## Installation

Le fichier `install.cmd` fourni reprend les commandes communiquées et copie les deux scripts. Vérifier le nom exact du registre : il utilise `bginforeg.reg`. Si le fichier porte un autre nom, corriger cette ligne.

## Test

Sur un poste de test, lancer l'icône, laisser la popup BGInfo ouverte, attendre le message de confirmation dans la fenêtre de commande, puis essayer **Ctrl+V** dans le Bloc-notes. Comparer les valeurs copiées à celles affichées avant le déploiement général.
