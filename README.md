# flask-mariadb-cicd

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
  ghcr.io/<Dkhallis>/flask-mariadb-cicd:latest
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