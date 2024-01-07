Hello leid falls ihr ned wisst wie ihr des rest-api bzw. mongo db starten kinnts. 

1) Flask installieren
   * in der console in Ordner 3 gehen
   * command ausführes: flask --app rest-api run
   * browser checken: http://127.0.0.1:5000/
2) mongo db the community edition: https://www.mongodb.com/docs/manual/installation/

### Dani TODO

- [ ] Init Flask: https://flask.palletsprojects.com/en/3.0.x/quickstart/
- [ ] mongo db
  - [ ] install: https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-ubuntu/#overview
  - [ ] integrate mongo db https://www.digitalocean.com/community/tutorials/how-to-use-mongodb-in-a-flask-application
  - [ ] save precomputed values in db
- [ ] Rest-endpoints
  - [ ] define
  - [ ] implement
- [ ] Deploying to Production: https://flask.palletsprojects.com/en/3.0.x/deploying/
- [ ] deinstall mongo db


## db user
db.createUser(
    {
    user: "AdminSammy",
    pwd: passwordPrompt(),
    roles: [ { role: "userAdminAnyDatabase", db: "admin" }, "readWriteAnyDatabase" ]
    }
    )

