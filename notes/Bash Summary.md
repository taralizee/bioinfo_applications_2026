# Summary BASH 
## Directory 
`pwd`--> were you are currently (present working directory)  
`mkdir` --> new directory  
`mkdir -p`-->  
`cd` file name --> change directory  
`cd` --> go back one level  

## Lists 
`ls` --> list / `ls -l` : long format / `ls -lh` : human readable format  
`ls > file_list.txt` --> save the list of files in a file  
`ls >> file_list.txt` --> add the list of files to an existing file  

## Modifier un Fichier
`echo text > file` --> rajoute text à un nouveau fichier  
`echo text >> file` --> rajoute text à un fichier déjà existant  
`mv file1 file2` --> renommer un fichier  
`mv file1 directory` --> déplacer un fichier dans un dossier  
`nano` --> editer un text (ctrl X puis Y puis enter pour sauvegarder)  

## Afficher un Fichier
`cat file`--> affiche le contenu d'un fichier  
`head file` --> affiche les 10 premières lignes d'un fichier (-n 1 : uniquement la premiere ligne)  
`tail file` --> affiche les 10 dernières lignes d'un fichier (-n 1 : uniquement la dernière ligne)  
`less` --> affiche continu d'un fichier  
 pour sortir de la vue `q` pour chercher `/`  

## Supprimer 
`rm file` --> supprimer un fichier  
`rm -r` directory --> supprime un dossier  
`rm *.sh` --> supprimer tous les fichiers .sh  
`rm test*` --> supprimer tous les fichiers qui commencent par test  
`cp file1 file2` --> copier un fichier / cp file1 directory --> copier un fichier dans un dossier  
`cp -r directory1 directory2` --> copier un dossier dans un autre dossier  
`mv file1 file2` --> renommer un fichier  
`mv file1 directory` --> déplacer un fichier dans un dossier  
`wc` --> word,line and character count  
`nano` --> editer un text (ctrl X puis Y puis enter pour sauvegarder)  

## Information 
`wc` --> word,line and character count  
`|` --> pipe : rediriger la sortie d'une commande vers une autre commande  
`grep` --> rechercher un motif dans un fichier  
`grep -i` : ignore case  
 `grep -r`  
`&&` --> exécuter la deuxième commande seulement si la première commande réussit   
`;` --> exécuter les commandes l'une après l'autre, indépendamment de leur succès  

## Télécharger 
`wget` --> télécharger un fichier depuis une URL  
`curl` --> transférer des données depuis ou vers un serveur  
