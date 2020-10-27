# **TP CITIZEN**

Créer une suite de smart contracts qui géreront un Etat et ses citoyens :

- _CitizenERC20.sol_ gere le token;
- _State.sol_ gere les affaires d'Etat.

## **le token `CITIZEN`**

Un token le `CITIZEN` (symbole `CTZ`, 18 decimales) servira de monnaie et de point de citoyenneté dans cet Etat.  
100 `CITIZEN` sont automatiquement attribués à un particulier qui souhaite devenir citoyen.
Lorsqu'un citoyen ne possède plus de `CITIZEN` (au moins une unite de CTZ) il ne peut plus voter.
L'entité qui sera l'Etat, (l'adresse d'un smart contract), devra posséder 100% du `cap` de `CITIZEN`.
L'État a 1 million de `CTZ` au deployement du contrat `CitizenERC20`, mais garde la possibilite de `burn` et `mint` des `CTZ` dans l'avenir (sans que le `totalSupply` of `CTZ` ne depasse pas le cap de 1 million).

## **Entreprises**

Les entreprises peuvent verser des salaires en `CITIZEN` aux salariés citoyens.  
Ces entreprises devront s'enregistrer auprès de l'Etat, et cet enregistrement devra être validé par le conseil des sages.
5000 `CITIZEN` sont automatiquement attribués à une entreprise qui s'enregistre dans notre Etat.

## **Administrateurs: conseil des sages**

Des administrateurs, qui forment le conseil des sages, pourront participer aux tâches de gouvernance et d'administration de l'Etat pour cela ils devront mettre en dépôt 100 `CITIZEN`.
Ce dépôt sera la garantie qu'ils feront correctement leur travail d'administrateur.
Les administrateurs votent pour effectuer les tâches d'administration comme utiliser les fonds des impôts récoltés, valider l'enregistrement d'une entreprise ou décider de donner des peines aux citoyens.  
Une mauvaise gestion consiste en un `crime contre la nation`.  
Les administrateurs sont élus par les citoyens. L'élection d'un administrateur dure 1 semaine.  
Ils sont élus pour une durée de 8 semaines. Pour assurer la continuite du service la periode des elections a lieu pendant la derniere semaine du mandat des administrateurs actuels.
Les administrateurs sont des citoyens qui peuvent effectuer des tâches d'administration.

## **Peines**

Dans cet Etat les peines consistent à se faire retirer du `CITIZEN`.
4 types de peines:

- légère: retire 5 `CITIZEN` au citoyen qui passe en jugement.
- lourde: retire 50 `CITIZEN` au citoyen qui passe en jugement.
- grave: retire 100 `CITIZEN` au citoyen qui passe en jugement.
- crime contre la nation: retire tous les `CITIZEN` du citoyen (compte courant, retraite, assurance maladie etc) et il est banni pendant 10 ans. Ses fonds sont ensuite reversés dans la caisse d'impôt commune.

## **Les citoyens**

Les citoyens sont identifiés par leur adresse Ethereum.
Il y a différents attributs qui définissent un citoyen (malade, chômage, banni etc.).  
Un citoyen peut se faire bannir pendant 10 ans.

## **Impôts**

Lorsqu'un citoyen perçoit des revenus, 10% sont automatiquement envoyés dans une caisse commune à tous les citoyens (l'adresse de l'Etat).
A tout moment les citoyens peuvent consulter combien la caisse contient.  
L'utilisation des fonds de cette caisse ne peut être effectué que par les sages.

## **Chômage**

Lorsqu'un citoyen perçoit des revenus, 10 % sont automatiquement envoyés dans une caisse d'allocation chômage. Cette somme est bloquée sur son compte. Il ne pourra en bénéficier que si il est au chômage.
Le statut de chômeur ne pourra être validé que par les sages.

## **Assurance maladie**

Lorsqu'un citoyen perçoit des revenus, 10% sont automatiquement envoyés dans sa caisse d'assurance maladie. Cette somme est bloquée sur son compte. Il ne pourra en bénéficier que si il est malade.
Le statut de congé maladie ne pourra être validé que par les sages.

## **Retraite**

Lorsqu'un citoyen perçoit des revenus en `CITIZEN`, 10% sont automatiquement mis en dépôt pour sa retraite. Cette somme est bloquée sur son compte. Il ne pourra retirer ces fonds qu'a ses 67 ans (on calcule 67 ans en semaines).

## **Décès**

Lorsqu'un citoyen décède, ses fonds sont versés dans la caisse d'impôts commune (l'adresse de l'Etat).
Ce transfer de fonds ne peut être effectué que par les sages.
