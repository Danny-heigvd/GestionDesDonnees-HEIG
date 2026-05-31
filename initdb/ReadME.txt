Choix de nettoyage et de modélisation

Les données sources contenaient plusieurs incohérences, notamment des formats de dates différents, des noms de types de mobilier variables, des matériaux écrits de plusieurs manières, ainsi que des liens entre signalements, interventions et mobilier écrits en texte libre.

Pour éviter de perdre les données au moment de l’import, les fichiers CSV ont d’abord été chargés dans un schéma `staging`, avec toutes les colonnes en `TEXT`. Les données ont ensuite été nettoyées et transformées avant d’être insérées dans les tables finales.

Les types de mobilier ont été normalisés avec `LOWER`, `TRIM` et des `CASE WHEN`. Par exemple, `lampadaire led`, `lampadaire public` et `lampadaire sodium` sont regroupés comme des lampadaires. Pour garder l’information demandée dans le brief, le type LED ou sodium est ensuite récupéré depuis le matériau.

Les dates ont été converties en format `DATE` avec `TO_DATE`, et les années seules ont été transformées en date au 1er janvier de l’année concernée. Les durées d’intervention ont été converties en minutes afin de pouvoir les comparer et les exploiter plus facilement.

Les coûts ont été nettoyés pour obtenir des valeurs numériques. Les mentions comme `gratuit` ou `garantie` ont été converties en `0`, tandis que les coûts vides restent à `NULL`.

Les signalements et interventions ne contenaient pas toujours directement l’identifiant du mobilier. Un rapprochement a donc été fait à partir du texte de l’objet, en utilisant le type de mobilier et le lieu lorsque c’était possible. Les lignes sans correspondance fiable ont été exclues afin d’éviter de créer de fausses relations.

Ces choix permettent d’obtenir une base plus cohérente pour produire les trois vues demandées : la fiche des lampadaires, le classement par priorité et la sélection dans le budget de CHF 50’000.

Réponse a la problématique

Le classement repose sur trois critères pondérés : le nombre de pannes (× 3) comme facteur dominant de fiabilité, l'âge en années (× 2) pour anticiper les défaillances futures, et le coût cumulé des interventions (/ 100) pour affiner le classement. Les lampadaires sans date d'installation se voient attribuer un âge conventionnel de 30 ans. Le budget de CHF 50 000.— permet de remplacer la totalité des 35 lampadaires recensés pour un coût estimé de CHF 5 139.62.—, avec priorité aux lampadaires 31 et 24 qui concentrent le plus de pannes et de coûts. Le solde de CHF 44 860.— pourrait être alloué à d'autres types de mobilier urbain.