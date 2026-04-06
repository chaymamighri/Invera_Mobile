from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

TARGET_FILES = [
    ROOT / "lib" / "main.dart",
    ROOT / "lib" / "config" / "app_globals.dart",
    ROOT / "lib" / "config" / "app_routes.dart",
    ROOT / "lib" / "core" / "ui" / "adaptive_layout.dart",
]
TARGET_FILES.extend(sorted((ROOT / "lib" / "views").rglob("*.dart")))


EXACT_MAP = {
    "---------- THEME CONSTANTS ----------": "---------- CONSTANTES DU THEME ----------",
    "---------- THEME CONSTANTS (reuse from clients section) ----------":
        "---------- CONSTANTES DU THEME (reprises depuis la section clients) ----------",
    "---------- REUSABLE WIDGETS ----------": "---------- WIDGETS REUTILISABLES ----------",
    "---------- HELPER WIDGETS ----------": "---------- WIDGETS UTILITAIRES ----------",
    "---------- MAIN SECTION ----------": "---------- SECTION PRINCIPALE ----------",
    "---------- UI ----------": "---------- INTERFACE ----------",
    "Shared top-level values used by the frontend.":
        "Valeurs globales partagees utilisees par l'interface.",
    "Configuration, dependencies, and local UI state.":
        "Configuration, dependances et etat local de l'interface.",
    "Widget lifecycle.": "Cycle de vie du widget.",
    "User actions and asynchronous workflows.":
        "Actions utilisateur et traitements asynchrones.",
    "Computed values and helper methods.":
        "Valeurs calculees et methodes utilitaires.",
    "UI builders.": "Construction de l'interface.",
    "Animation controllers for hover effects (optional, can be omitted)":
        "Controleurs d'animation pour les effets de survol (optionnels, peuvent etre omis)",
    "CRUD operations (unchanged from original but with improved UI feedback)":
        "Operations CRUD (inchangées par rapport a l'original, avec un meilleur retour visuel)",
    "Decide on presentation: bottom sheet for small screens, dialog for larger":
        "Choix d'affichage : bottom sheet sur petit ecran, dialogue sur grand ecran",
    "Helper classes": "Classes utilitaires",
    "Important fix:": "Correction importante :",
    "Improved client form (dialog or bottom sheet based on screen size)":
        "Formulaire client ameliore (dialogue ou bottom sheet selon la taille de l'ecran)",
    "Sortable header": "En-tete triable",
    "Sorting": "Tri",
    "Sorting logic": "Logique de tri",
    "before disposing controllers used by TextFormField.":
        "avant de liberer les controleurs utilises par TextFormField.",
    "wait until the dialog is fully removed from the widget tree":
        "attendre que le dialogue soit completement retire de l'arbre des widgets",
    "Starts the Flutter application.": "Lance l'application Flutter.",
    "Central list of named routes used by the app.":
        "Liste centrale des routes nommees utilisees par l'application.",
    "Reusable helpers for responsive spacing and size calculations.":
        "Utilitaires reutilisables pour l'espacement adaptatif et les calculs de taille.",
    "Root widget that configures navigation, routes, and theme.":
        "Widget racine qui configure la navigation, les routes et le theme.",
    "Builds the visible UI for this widget.":
        "Construit l'interface visible de ce widget.",
    "Creates the mutable state object for this widget.":
        "Cree l'objet d'etat mutable de ce widget.",
    "Runs once when the widget is inserted into the tree.":
        "S'execute une seule fois quand le widget est insere dans l'arbre des widgets.",
    "Cleans up controllers and listeners before the widget is destroyed.":
        "Libere les controleurs et les ecouteurs avant la destruction du widget.",
    "Loads the data.": "Charge les donnees.",
    "Reloads the current data.": "Recharge les donnees actuelles.",
    "Runs the request safely and falls back when it fails.":
        "Execute la requete de maniere sure et utilise une valeur de secours en cas d'echec.",
    "Submits the current form data.":
        "Soumet les donnees actuelles du formulaire.",
    "Calculates the total.": "Calcule le total.",
    "Validates the email.": "Valide l'adresse e-mail.",
    "Handles the login.": "Gere la connexion.",
    "Checks whether the current screen width matches a phone layout.":
        "Verifie si la largeur actuelle de l'ecran correspond a une mise en page telephone.",
    "Checks whether the current screen width matches a tablet layout.":
        "Verifie si la largeur actuelle de l'ecran correspond a une mise en page tablette.",
    "Checks whether the value has min length.":
        "Verifie si la valeur a une longueur minimale.",
    "Checks whether the value has uppercase.":
        "Verifie si la valeur contient une majuscule.",
    "Checks whether the value has digit.":
        "Verifie si la valeur contient un chiffre.",
    "Checks whether the value has special character.":
        "Verifie si la valeur contient un caractere special.",
    "Checks whether the widget can generate invoice PDF.":
        "Verifie si le widget peut generer le PDF de la facture.",
    "Possible auth banner tone values used by this file.":
        "Valeurs possibles de tonalite de la banniere d'authentification utilisees dans ce fichier.",
    "Shared color palette used by the auth UI.":
        "Palette de couleurs partagee utilisee par l'interface d'authentification.",
    "Shows the confirmation dialog.":
        "Affiche le dialogue de confirmation.",
    "Shows the message.": "Affiche le message.",
    "Deletes the order.": "Supprime la commande.",
    "Restores the order.": "Restaure la commande.",
    "Marks the order as invoiced.": "Marque la commande comme facturee.",
    "Exports the facture PDF.": "Exporte le PDF de la facture.",
    "Exports the invoice PDF.": "Exporte le PDF de la facture.",
    "Exports the procurement invoice PDF.":
        "Exporte le PDF de la facture d'approvisionnement.",
    "Returns a display label for the status.":
        "Retourne un libelle d'affichage pour le statut.",
    "Clears the selected image.": "Efface l'image selectionnee.",
    "Formats the date for UI for display.":
        "Formate la date pour l'affichage dans l'interface.",
    "Opens the profile.": "Ouvre le profil.",
    "Toggles the sidebar.": "Bascule l'etat de la barre laterale.",
    "Updates the active page.": "Met a jour la page active.",
    "Builds the initials displayed in the avatar.":
        "Construit les initiales affichees dans l'avatar.",
    "Returns a copy of this object with the provided changes.":
        "Retourne une copie de cet objet avec les modifications fournies.",
    "Responds when password change changes.":
        "Reagit lorsque le mot de passe change.",
    "Responds when password changed changes.":
        "Reagit lorsque le mot de passe change.",
    "Verifie si commande visible in actuel mode.":
        "Verifie si la commande est visible dans le mode actuel.",
    "Widget qui affiche authentification arriere-plan decor.":
        "Widget qui affiche le decor d'arriere-plan d'authentification.",
    "Formate date for interface pour l'affichage.":
        "Formate la date pour l'affichage dans l'interface.",
    "Verifie si authentification erreur.":
        "Verifie s'il s'agit d'une erreur d'authentification.",
    "Classe utilitaire pour approvisionnement dashboard etat.":
        "Classe utilitaire pour l'etat du tableau de bord d'approvisionnement.",
    "Classe utilitaire pour commercial analytics dashboard etat.":
        "Classe utilitaire pour l'etat du tableau de bord analytique commercial.",
    "Classe utilitaire pour approvisionnement categories section etat.":
        "Classe utilitaire pour l'etat de la section des categories d'approvisionnement.",
    "Classe utilitaire pour approvisionnement vue d'ensemble section etat.":
        "Classe utilitaire pour l'etat de la section de vue d'ensemble de l'approvisionnement.",
    "Classe utilitaire pour approvisionnement produits section etat.":
        "Classe utilitaire pour l'etat de la section des produits d'approvisionnement.",
    "Classe utilitaire pour approvisionnement commande formulaire dialogue etat.":
        "Classe utilitaire pour l'etat du dialogue du formulaire de commande d'approvisionnement.",
}


PHRASE_MAP = {
    "active page": "la page active",
    "animated page content": "le contenu de page anime",
    "approvisionnement dashboard": "le tableau de bord d'approvisionnement",
    "approvisionnement dashboard state": "l'etat du tableau de bord d'approvisionnement",
    "async error card": "la carte d'erreur asynchrone",
    "auth back button": "le bouton retour d'authentification",
    "auth background decor": "le decor d'arriere-plan d'authentification",
    "auth banner": "la banniere d'authentification",
    "auth primary button": "le bouton principal d'authentification",
    "auth rule": "la regle d'authentification",
    "auth rule checklist": "la liste de verification des regles d'authentification",
    "auth rule tile": "la tuile de regle d'authentification",
    "auth scaffold": "la structure d'authentification",
    "auth text field": "le champ de texte d'authentification",
    "available types": "les types disponibles",
    "avg order": "la moyenne par commande",
    "badge": "le badge",
    "belongs to date range": "l'appartenance a la plage de dates",
    "card width that fits the current screen": "la largeur de carte adaptee a l'ecran actuel",
    "category edit toast dialog": "le dialogue toast de modification de categorie",
    "category mobile tile": "la tuile mobile de categorie",
    "change password dialog": "le dialogue de changement de mot de passe",
    "client form result": "le resultat du formulaire client",
    "client form surface": "la surface du formulaire client",
    "client revenue point": "le point de chiffre d'affaires client",
    "client type": "le type de client",
    "commande card": "la carte de commande",
    "commande detail row": "la ligne de detail de la commande",
    "commande details": "les details de la commande",
    "commande form result": "le resultat du formulaire de commande",
    "commande subtotal": "le sous-total de la commande",
    "commandes by creation": "les commandes par creation",
    "commercial analytics dashboard": "le tableau de bord analytique commercial",
    "commercial analytics dashboard state": "l'etat du tableau de bord analytique commercial",
    "commercial clients section": "la section des clients commerciaux",
    "commercial commandes section": "la section des commandes commerciales",
    "commercial dashboard": "le tableau de bord commercial",
    "commercial factures section": "la section des factures commerciales",
    "compact amount": "le montant compact",
    "compose supplier location": "la localisation du fournisseur",
    "confirm logout": "la confirmation de deconnexion",
    "count pill": "la pastille de compteur",
    "current data": "les donnees actuelles",
    "current form data": "les donnees actuelles du formulaire",
    "current screen size": "la taille actuelle de l'ecran",
    "date filter sheet": "la feuille de filtre par date",
    "date range label": "le libelle de la plage de dates",
    "date time": "la date et l'heure",
    "day only": "la date seule",
    "desktop action button": "le bouton d'action du mode bureau",
    "desktop top bar": "la barre superieure du mode bureau",
    "detail badge": "le badge de detail",
    "detail info card": "la carte d'information detaillee",
    "details section": "la section de details",
    "dialog height that fits the current screen": "la hauteur de dialogue adaptee a l'ecran actuel",
    "dialog width that fits the current screen": "la largeur de dialogue adaptee a l'ecran actuel",
    "donut painter": "le peintre de diagramme en anneau",
    "donut segment": "le segment de diagramme en anneau",
    "drawer width that fits the current screen": "la largeur du tiroir adaptee a l'ecran actuel",
    "draft order line": "la ligne brouillon de commande",
    "email": "l'e-mail",
    "empty panel": "le panneau vide",
    "ensure facture for commande": "la creation d'une facture pour la commande",
    "error message": "le message d'erreur",
    "existing image url": "l'url de l'image existante",
    "facture details": "les details de la facture",
    "facture flow": "le flux de facture",
    "facture pdf": "le PDF de la facture",
    "facture pdf bytes": "les octets du PDF de la facture",
    "facture reference": "la reference de facture",
    "facture status label": "le libelle du statut de facture",
    "filtered orders": "les commandes filtrees",
    "forgot password screen": "l'ecran de recuperation du mot de passe",
    "form": "le formulaire",
    "form actions": "les actions du formulaire",
    "form card": "la carte du formulaire",
    "form header": "l'en-tete du formulaire",
    "generating for": "la generation est en cours",
    "glow orb": "l'orbe lumineuse",
    "header": "l'en-tete",
    "header stat pill": "la pastille statistique d'en-tete",
    "hero chip": "la pastille hero",
    "horizontal padding for the current screen size": "l'espacement horizontal pour la taille actuelle de l'ecran",
    "image": "l'image",
    "image mime type": "le type MIME de l'image",
    "image placeholder": "l'espace reserve de l'image",
    "image section": "la section image",
    "info badge": "le badge d'information",
    "info row": "la ligne d'information",
    "info stat card": "la carte de statistique d'information",
    "invoice action": "l'action de facturation",
    "invoice pdf": "le PDF de la facture",
    "invoiced": "la commande est facturee",
    "is editing": "l'etat de modification",
    "kpi tile": "la tuile d'indicateur cle",
    "label shown for the current user role": "le libelle affiche pour le role actuel de l'utilisateur",
    "loading panel": "le panneau de chargement",
    "login screen": "l'ecran de connexion",
    "logout": "la deconnexion",
    "low stock tile": "la tuile de stock faible",
    "message": "le message",
    "meta tile": "la tuile meta",
    "metric": "la metrique",
    "mini metric": "la mini metrique",
    "mobile app bar": "la barre d'application mobile",
    "module theme": "le theme du module",
    "monthly sales point": "le point de ventes mensuelles",
    "nice axis max": "la valeur maximale harmonieuse de l'axe",
    "normalized range": "la plage normalisee",
    "order": "la commande",
    "order card": "la carte de commande",
    "order details": "les details de la commande",
    "order details dialog": "le dialogue des details de la commande",
    "order dialog": "le dialogue de commande",
    "order dialog result": "le resultat du dialogue de commande",
    "order visible in current mode": "la commande est visible dans le mode actuel",
    "order status bucket": "le groupe de statuts de commande",
    "order summary tile": "la tuile recapitulative de commande",
    "orders for current mode": "les commandes du mode actuel",
    "orders panel": "le panneau des commandes",
    "page content": "le contenu de la page",
    "page subtitle": "le sous-titre de la page",
    "page title": "le titre de la page",
    "paint": "le dessin",
    "panel": "le panneau",
    "parse commande creation date": "l'analyse de la date de creation de la commande",
    "parse commande date": "l'analyse de la date de la commande",
    "parse flexible date": "l'analyse d'une date flexible",
    "password change": "le mot de passe",
    "password changed": "le mot de passe",
    "password rule": "la regle du mot de passe",
    "password score": "le score du mot de passe",
    "password strength color": "la couleur de la force du mot de passe",
    "password strength label": "le libelle de la force du mot de passe",
    "pending commandes": "les commandes en attente",
    "procurement categories section": "la section des categories d'approvisionnement",
    "procurement categories section state": "l'etat de la section des categories d'approvisionnement",
    "procurement invoice line": "la ligne de facture d'approvisionnement",
    "procurement invoice pdf": "le PDF de la facture d'approvisionnement",
    "procurement invoice pdf bytes": "les octets du PDF de la facture d'approvisionnement",
    "procurement invoice reference": "la reference de facture d'approvisionnement",
    "procurement order dialog result": "le resultat du dialogue de commande d'approvisionnement",
    "procurement order form dialog": "le dialogue du formulaire de commande d'approvisionnement",
    "procurement order form dialog state":
        "l'etat du dialogue du formulaire de commande d'approvisionnement",
    "procurement orders section": "la section des commandes d'approvisionnement",
    "procurement overview section": "la section de vue d'ensemble de l'approvisionnement",
    "procurement overview section state":
        "l'etat de la section de vue d'ensemble de l'approvisionnement",
    "procurement products section": "la section des produits d'approvisionnement",
    "procurement products section state":
        "l'etat de la section des produits d'approvisionnement",
    "product action button": "le bouton d'action produit",
    "product avatar": "l'avatar du produit",
    "product card": "la carte produit",
    "product form dialog": "le dialogue du formulaire produit",
    "product soft tag": "l'etiquette legere du produit",
    "product spec panel": "le panneau de specifications du produit",
    "product spec row": "la ligne de specifications du produit",
    "products preview": "l'apercu des produits",
    "profile": "le profil",
    "profile screen": "l'ecran de profil",
    "profile setting input": "le champ des parametres du profil",
    "profile settings dialog": "le dialogue des parametres du profil",
    "produit detail card": "la carte detaillee du produit",
    "purchase draft line": "la ligne brouillon d'achat",
    "purchase order form dialog": "le dialogue du formulaire de bon de commande",
    "purchase order form dialog legacy state": "l'ancien etat du dialogue du formulaire de bon de commande",
    "quantity": "la quantite",
    "recent": "les elements recents",
    "recent orders list": "la liste des commandes recentes",
    "reset password screen": "l'ecran de reinitialisation du mot de passe",
    "responsable vente dashboard": "le tableau de bord du responsable des ventes",
    "revenue": "le chiffre d'affaires",
    "run order action": "l'execution de l'action de commande",
    "same date range": "la plage de dates est identique",
    "sales trend chart": "le graphique de tendance des ventes",
    "sales trend painter": "le peintre de tendance des ventes",
    "sanitize file name": "le nettoyage du nom de fichier",
    "search haystack": "la chaine de recherche",
    "search query terms": "les termes de la recherche",
    "search text": "le texte de recherche",
    "section marker": "le repere de section",
    "section surface": "la surface de section",
    "secure password input": "le champ securise du mot de passe",
    "security row": "la ligne de securite",
    "selected image": "l'image selectionnee",
    "sep": "le separateur",
    "shell backdrop": "la toile de fond de l'enveloppe",
    "should repaint": "la necessite de repeindre",
    "sidebar": "la barre laterale",
    "sidebar item": "l'element de barre laterale",
    "sidebar section": "la section de barre laterale",
    "status": "le statut",
    "status breakdown card": "la carte de repartition des statuts",
    "status chip": "la pastille de statut",
    "status color": "la couleur du statut",
    "status donut card": "la carte en anneau des statuts",
    "status pill": "la pastille de statut",
    "stock adjust dialog": "le dialogue d'ajustement du stock",
    "summary tile": "la tuile recapitulative",
    "table header": "l'en-tete de tableau",
    "text field": "le champ de texte",
    "top actions": "les actions principales",
    "top clients list": "la liste des meilleurs clients",
    "total": "le total",
    "total ttc": "le total TTC",
    "type distribution bars": "les barres de repartition par type",
    "unit price": "le prix unitaire",
    "value has digit": "la valeur contient un chiffre",
    "value has min length": "la valeur a une longueur minimale",
    "value has special character": "la valeur contient un caractere special",
    "value has uppercase": "la valeur contient une majuscule",
    "visible commandes": "les commandes visibles",
    "visible ui": "l'interface visible",
}


PATTERNS = [
    (re.compile(r"^Widget that renders the (.+)\.$"), lambda m: f"Widget qui affiche {translate_phrase(m.group(1))}."),
    (
        re.compile(r"^State object that stores the temporary UI data for (.+)\.$"),
        lambda m: f"Objet d'etat qui stocke les donnees temporaires de l'interface pour {translate_phrase(m.group(1))}.",
    ),
    (re.compile(r"^Helper class for (.+)\.$"), lambda m: f"Classe utilitaire pour {translate_phrase(m.group(1))}."),
    (
        re.compile(r"^Small helper model that stores (.+) data\.$"),
        lambda m: f"Petit modele utilitaire qui stocke les donnees de {translate_phrase(m.group(1))}.",
    ),
    (re.compile(r"^Builds an? (.+)\.$"), lambda m: f"Construit {translate_phrase(m.group(1))}."),
    (re.compile(r"^Builds the (.+)\.$"), lambda m: f"Construit {translate_phrase(m.group(1))}."),
    (re.compile(r"^Returns the (.+)\.$"), lambda m: f"Retourne {translate_phrase(m.group(1))}."),
    (re.compile(r"^Checks whether (.+) is true\.$"), lambda m: f"Verifie si {translate_phrase(m.group(1))}."),
    (re.compile(r"^Formats the (.+) for display\.$"), lambda m: f"Formate {translate_phrase(m.group(1))} pour l'affichage."),
    (re.compile(r"^Shows the (.+)\.$"), lambda m: f"Affiche {translate_phrase(m.group(1))}."),
    (re.compile(r"^Opens the (.+)\.$"), lambda m: f"Ouvre {translate_phrase(m.group(1))}."),
    (re.compile(r"^Handles the (.+)\.$"), lambda m: f"Gere {translate_phrase(m.group(1))}."),
    (re.compile(r"^Deletes the (.+)\.$"), lambda m: f"Supprime {translate_phrase(m.group(1))}."),
    (re.compile(r"^Restores the (.+)\.$"), lambda m: f"Restaure {translate_phrase(m.group(1))}."),
    (re.compile(r"^Exports the (.+)\.$"), lambda m: f"Exporte {translate_phrase(m.group(1))}."),
    (re.compile(r"^Normalizes the (.+)\.$"), lambda m: f"Normalise {translate_phrase(m.group(1))}."),
    (
        re.compile(r"^Sorts the (.+) into the desired order\.$"),
        lambda m: f"Trie {translate_phrase(m.group(1))} dans l'ordre souhaite.",
    ),
    (
        re.compile(r"^Lets the user pick the (.+)\.$"),
        lambda m: f"Permet a l'utilisateur de choisir {translate_phrase(m.group(1))}.",
    ),
    (re.compile(r"^Guesses the (.+)\.$"), lambda m: f"Determine automatiquement {translate_phrase(m.group(1))}."),
    (
        re.compile(r"^Cleans the (.+) before showing it\.$"),
        lambda m: f"Nettoie {translate_phrase(m.group(1))} avant l'affichage.",
    ),
    (re.compile(r"^Copies the (.+)\.$"), lambda m: f"Copie {translate_phrase(m.group(1))}."),
    (re.compile(r"^Counts the (.+)\.$"), lambda m: f"Compte {translate_phrase(m.group(1))}."),
    (re.compile(r"^Validates the (.+)\.$"), lambda m: f"Valide {translate_phrase(m.group(1))}."),
    (re.compile(r"^Toggles the (.+)\.$"), lambda m: f"Bascule {translate_phrase(m.group(1))}."),
    (
        re.compile(r"^Marks the (.+) as invoiced\.$"),
        lambda m: f"Marque {translate_phrase(m.group(1))} comme facturee.",
    ),
    (
        re.compile(r"^Possible (.+) values used by this file\.$"),
        lambda m: f"Valeurs possibles de {translate_phrase(m.group(1))} utilisees dans ce fichier.",
    ),
    (
        re.compile(r"^Responds when (.+) changes\.$"),
        lambda m: f"Reagit lorsque {translate_phrase(m.group(1))} change.",
    ),
    (re.compile(r"^Helper method for (.+)\.$"), lambda m: f"Methode utilitaire pour {translate_phrase(m.group(1))}."),
]


TOKEN_REPLACEMENTS = {
    "approvisionnement": "approvisionnement",
    "async": "asynchrone",
    "auth": "authentification",
    "avatar": "avatar",
    "badge": "badge",
    "bar": "barre",
    "background": "arriere-plan",
    "backdrop": "toile de fond",
    "back": "retour",
    "banner": "banniere",
    "button": "bouton",
    "bytes": "octets",
    "card": "carte",
    "categories": "categories",
    "category": "categorie",
    "change": "changement",
    "chart": "graphique",
    "checklist": "liste de verification",
    "chip": "pastille",
    "clients": "clients",
    "client": "client",
    "color": "couleur",
    "commandes": "commandes",
    "commande": "commande",
    "commercial": "commercial",
    "compact": "compact",
    "confirmation": "confirmation",
    "content": "contenu",
    "count": "compteur",
    "current": "actuel",
    "date": "date",
    "decor": "decor",
    "detail": "detail",
    "details": "details",
    "dialog": "dialogue",
    "distribution": "repartition",
    "drawer": "tiroir",
    "editing": "modification",
    "email": "e-mail",
    "empty": "vide",
    "error": "erreur",
    "facture": "facture",
    "field": "champ",
    "filter": "filtre",
    "flow": "flux",
    "forgot": "oubli",
    "form": "formulaire",
    "generating": "generation",
    "glow": "lumineuse",
    "header": "en-tete",
    "hero": "hero",
    "image": "image",
    "info": "information",
    "initials": "initiales",
    "invoice": "facture",
    "item": "element",
    "layout": "mise en page",
    "line": "ligne",
    "list": "liste",
    "loading": "chargement",
    "login": "connexion",
    "logout": "deconnexion",
    "low": "faible",
    "main": "principal",
    "meta": "meta",
    "metric": "metrique",
    "mime": "MIME",
    "mini": "mini",
    "mobile": "mobile",
    "module": "module",
    "monthly": "mensuel",
    "order": "commande",
    "orders": "commandes",
    "orb": "orbe",
    "overview": "vue d'ensemble",
    "page": "page",
    "paint": "dessin",
    "panel": "panneau",
    "password": "mot de passe",
    "pending": "en attente",
    "phone": "telephone",
    "pill": "pastille",
    "primary": "principal",
    "procurement": "approvisionnement",
    "product": "produit",
    "products": "produits",
    "profile": "profil",
    "quantity": "quantite",
    "range": "plage",
    "recent": "recent",
    "reference": "reference",
    "reload": "rechargement",
    "reset": "reinitialisation",
    "revenue": "chiffre d'affaires",
    "row": "ligne",
    "rule": "regle",
    "sales": "ventes",
    "screen": "ecran",
    "search": "recherche",
    "section": "section",
    "secure": "securise",
    "security": "securite",
    "selected": "selectionne",
    "sep": "separateur",
    "settings": "parametres",
    "shell": "enveloppe",
    "sidebar": "barre laterale",
    "soft": "legere",
    "spec": "specification",
    "stat": "statistique",
    "state": "etat",
    "status": "statut",
    "stock": "stock",
    "subtitle": "sous-titre",
    "summary": "recapitulatif",
    "surface": "surface",
    "table": "tableau",
    "tablet": "tablette",
    "text": "texte",
    "theme": "theme",
    "tile": "tuile",
    "top": "meilleur",
    "total": "total",
    "trend": "tendance",
    "type": "type",
    "types": "types",
    "ui": "interface",
    "unit": "unitaire",
    "url": "url",
    "user": "utilisateur",
    "value": "valeur",
    "visible": "visible",
    "width": "largeur",
}


def translate_phrase(phrase: str) -> str:
    cleaned = phrase.strip().rstrip(".")
    key = cleaned.lower()
    if key in PHRASE_MAP:
        return PHRASE_MAP[key]

    translated = key
    for source, target in sorted(TOKEN_REPLACEMENTS.items(), key=lambda item: len(item[0]), reverse=True):
        translated = re.sub(rf"\b{re.escape(source)}\b", target, translated)

    translated = translated.replace("  ", " ").strip()
    return translated


def translate_body(body: str) -> str:
    if body in EXACT_MAP:
        return EXACT_MAP[body]

    for pattern, replacer in PATTERNS:
        match = pattern.match(body)
        if match:
            return replacer(match)

    return body


def apply_french_cleanup(text: str) -> str:
    cleaned = text
    cleaned = cleaned.replace(" de le ", " du ")
    cleaned = cleaned.replace(" de les ", " des ")
    cleaned = cleaned.replace(" a le ", " au ")
    cleaned = cleaned.replace(" a les ", " aux ")
    cleaned = cleaned.replace(" le ecran", " l'ecran")
    cleaned = cleaned.replace(" le etat", " l'etat")
    cleaned = cleaned.replace(" le interface", " l'interface")
    cleaned = cleaned.replace(" le url", " l'url")
    cleaned = cleaned.replace(" la e-mail", " l'e-mail")
    cleaned = cleaned.replace(" le e-mail", " l'e-mail")
    cleaned = cleaned.replace(" la image", " l'image")
    cleaned = cleaned.replace(" le image", " l'image")
    return cleaned


def translate_line(line: str) -> str:
    stripped = line.lstrip()
    indent = line[: len(line) - len(stripped)]

    if stripped.startswith("// ignore") or stripped.startswith("// ignore_for_file"):
        return line

    if stripped.startswith("/// "):
        body = stripped[4:]
        return f"{indent}/// {apply_french_cleanup(translate_body(body))}"

    if stripped.startswith("// "):
        body = stripped[3:]
        return f"{indent}// {apply_french_cleanup(translate_body(body))}"

    return line


def main() -> None:
    for file_path in TARGET_FILES:
        original = file_path.read_text(encoding="utf-8")
        translated = "\n".join(translate_line(line) for line in original.splitlines()) + "\n"
        if translated != original:
            file_path.write_text(translated, encoding="utf-8")


if __name__ == "__main__":
    main()
