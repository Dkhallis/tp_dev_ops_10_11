# tp_dev_ops_10_11

Petite appli Flask qui teste la connexion à une base MariaDB.
La page d'accueil affiche "Database Connection Status: Connected" si la base répond, sinon "Disconnected".

## Config

L'appli lit ces variables d'environnement :

- DB_HOST (par défaut localhost)
- DB_USER (par défaut root)
- DB_PASSWORD (vide par défaut)
- DB_NAME (par défaut test)

## Lancer avec Docker

Il faut d'abord une base MariaDB, on met les deux conteneurs sur le même réseau :

```bash
docker network create app-net

docker run -d --name db --network app-net \
  -e MARIADB_ROOT_PASSWORD=monmdp \
  -e MARIADB_DATABASE=appdb \
  mariadb:11.4
```

Ensuite l'appli (image récupérée depuis GHCR) :

```bash
docker run -d --name app --network app-net -p 5000:5000 \
  -e DB_HOST=db -e DB_USER=root -e DB_PASSWORD=monmdp -e DB_NAME=appdb \
  ghcr.io/dkhallis/flask-mariadb-cicd:latest
```

L'appli est dispo sur http://localhost:5000

Si on veut builder l'image soi-même : `docker build -t flask-mariadb-cicd .`

## Lancer sans Docker

```bash
python -m venv .venv
source .venv/bin/activate    # sous Windows : .venv\Scripts\activate
pip install -r requirements.txt

export DB_HOST=localhost DB_USER=root DB_PASSWORD=monmdp DB_NAME=appdb
python app.py
```

## Commits

J'utilise les Conventional Commits (feat:, fix:, docs:, ci:, test:...).

## CI/CD

### Publication de l'image

Le workflow `.github/workflows/publish.yml` build l'image et la pousse sur GHCR à chaque push sur main.
Elle est taguée `latest` + le SHA du commit. Quand on pousse un tag `vX.Y.Z`, l'image est aussi publiée avec la version (ex : `1.0.0`).
La connexion à GHCR utilise le `GITHUB_TOKEN` fourni par GitHub, donc pas de mot de passe dans le repo.

Le package est public :

```bash
docker pull ghcr.io/<compte>/flask-mariadb-cicd:1.0.0
```

### Test avant merge

À chaque PR vers main, `.github/workflows/functional-test.yml` lance `tests/functional_test.sh` :
- démarre un conteneur MariaDB (mot de passe généré au moment du test)
- build et démarre l'appli sur le même réseau
- appelle la page d'accueil et vérifie que la réponse est exactement "Database Connection Status: Connected"

Si la réponse est différente, le script sort en erreur et le check est rouge.

La branche main est protégée : PR obligatoire et le check `functional-test` doit passer pour pouvoir merger.