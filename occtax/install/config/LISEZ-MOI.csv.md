Export des données Observations occasionnelles conforme au standard de la plateforme thématique du SINP (V2)
=================================================================================================================

Pour plus de lisibilité, il est recommandé d’ouvrir les fichiers contenus dans cet export à l’aide du logiciel Libre Office Calc (encodage : UTF 8). Seuls les fichiers de type csv doivent être ouverts.

Le dossier d’export est constitué de plusieurs fichiers « st_principal » suffixés selon le type de géométrie (points, lignes, polygones ou sans géométrie) contenant chacun les informations relatives aux observations du type géométrique cité. Le sous dossier « rattachements » contient quant à lui les fichiers permettant le rattachement des observations aux objets géographiques suivants :

   * st_commune : localisation à la commune (lien avec st_principal sur la colonne cle_obs)
   * st_departement : localisation au département (lien avec st_principal sur la colonne cle_obs)
   * st_maille_02 : localisation à la maille 2x2km (lien avec st_principal sur la colonne cle_obs)
   * st_maille_10 : localisation à la maille 10x10km (lien avec st_principal sur la colonne cle_obs)
   * st_espace_naturel : localisation à l'espace naturel (lien avec st_principal sur la colonne cle_obs)
   * st_habitat : localisation à l’habitat naturel (lien avec st_principal sur la colonne cle_obs)
   * st_masse_eau : localisation à la masse d'eau (lien avec st_principal sur la colonne cle_obs)

Le détail de la signification des champs est indiqué dans le standard national occurrence de taxons consultable et téléchargeable à l’adresse suivante : http://standards-sinp.mnhn.fr/occurrences_de_taxons_v1-2-1/.

Les données mises à disposition sont issues de nombreux producteurs ayant versé leurs données au SINP dans un cadre très précis prévoyant les modalités d’échanges et de réutilisation de données aux niveaux régional et national.

Par conséquent, l’utilisateur ne disposant pas d’identifiants de connexion s’engage à respecter les règles de réutilisation des données définies par la licence ouverte figurant en annexe D du protocole national du SINP téléchargeable à cette adresse : http://www.naturefrance.fr/sinp/presentation-du-sinp/protocole-du-sinp.
