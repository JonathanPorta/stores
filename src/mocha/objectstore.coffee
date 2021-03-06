path = require "path"
root = path.join __dirname, "..", ".."
should = require("chai").should()

JEFRi = require "jefri"
Stores = require "../../lib/jefri-stores"
Stores = Stores.Stores
express = require "express"

describe "ObjectStore", ->
	runtime = ->
	testId = ""
	before ->
		app =
			express()
				.get '/context.json', (req, res)->
					res.set "content-type", "application/json"
					res.sendfile path.join root, "src", "mocha", "context.json"
		app.listen 3030, ->
			runtime = new JEFRi.Runtime "http://localhost:3030/context.json"

	describe "Basic Build, Persist and Getting.", ->
		it "builds and persists two entities", (done)->
			runtime.ready.done ->
				store = new Stores.ObjectStore runtime: runtime
				transaction = new JEFRi.Transaction()
				user = runtime.build "User",
					name: "southerd"
					address: "davidsouther@gmail.com"
				user.authinfo = runtime.build "Authinfo", {}
				authinfo = user.authinfo
				transaction.add user, authinfo
				testId = user.id()
				store.persist(transaction)
				.then (transaction)->
					transaction.hasOwnProperty("entities").should.equal true
					transaction.hasOwnProperty("attributes").should.equal true
					transaction.entities.length.should.equal 2
					done()

		it "builds, persists and then gets an entity by id", (done)->
			runtime.ready.done ->
				store = new Stores.ObjectStore runtime: runtime
				transaction = new JEFRi.Transaction()
				user = runtime.build "User",
					name: "southerd"
					address: "davidsouther@gmail.com"
				user.authinfo = runtime.build "Authinfo", {}
				authinfo = user.authinfo
				transaction.add user, authinfo
				testId = user.id()
				store.persist(transaction)
				.then (transaction)->
					transaction.hasOwnProperty("entities").should.equal true
					transaction.hasOwnProperty("attributes").should.equal true
					transaction.entities.length.should.equal 2
					transaction2 = new JEFRi.Transaction()
					transaction2.add {_type:"User", user_id:testId}
					store.get(transaction2)
					.then (transaction2)->
						transaction2.hasOwnProperty("entities").should.equal true
						transaction2.hasOwnProperty("attributes").should.equal true
						transaction2.entities.length.should.equal 1
						transaction2.entities[0].user_id.should.equal testId
						transaction2.entities[0].name.should.equal "southerd"#test this to make sure it didn't only send back your spec.
						done()

		it "builds, persists and then gets an entity by one of its properties", (done)->
			runtime.ready.done ->
				store = new Stores.ObjectStore runtime: runtime
				transaction = new JEFRi.Transaction()
				user = runtime.build "User",
					name: "southerd"
					address: "davidsouther@gmail.com"
				user.authinfo = runtime.build "Authinfo", {}
				authinfo = user.authinfo
				transaction.add user, authinfo
				testId = user.id()
				store.persist(transaction)
				.then (transaction)->
					transaction.hasOwnProperty("entities").should.equal true
					transaction.hasOwnProperty("attributes").should.equal true
					transaction.entities.length.should.equal 2
					transaction2 = new JEFRi.Transaction()
					transaction2.add {_type:"User", name:"southerd"}
					store.get(transaction2)
					.then (transaction2)->
						transaction2.hasOwnProperty("entities").should.equal true
						transaction2.hasOwnProperty("attributes").should.equal true
						transaction2.entities.length.should.equal 1
						transaction2.entities[0].user_id.should.equal testId#test this to make sure it didn't only send back your spec.
						transaction2.entities[0].name.should.equal "southerd"
						done()

		it "builds, persists and then gets several entities by property", (done)->
			runtime.ready.done ->
				store = new Stores.ObjectStore runtime: runtime
				transaction = new JEFRi.Transaction()
				users = [
					{name: "southerd", address: "davidsouther@gmail.com", gender: "male"}
					{name: "levinea", address: "annie@levine.com", gender: "female"}
					{name: "portaj", address: "jonathan@jonathanporta.com", gender: "male"}
					{name: "pochaj", address: "jessicapocha@gmail.com", gender: "female"}
				]
				for u in users
					user = runtime.build "User", u
					user.authinfo = runtime.build "Authinfo", {}
					authinfo = user.authinfo
					transaction.add user, authinfo
				store.persist(transaction)
				.then (transaction)->
					transaction.hasOwnProperty("entities").should.equal true
					transaction.hasOwnProperty("attributes").should.equal true
					transaction.entities.length.should.equal 8 #a user entity plus authinfo for each
					transaction2 = new JEFRi.Transaction()
					transaction2.add {_type:"User", gender:"female"}
					store.get(transaction2)
					.then (transaction2)->
						transaction2.hasOwnProperty("entities").should.equal true
						transaction2.hasOwnProperty("attributes").should.equal true
						transaction2.entities.length.should.equal 2
						transaction2.entities[0].gender.should.equal "female"
						transaction2.entities[1].gender.should.equal "female"
						done()

		it "builds, persists and then gets entity by id with one relationship", (done)->
			runtime.ready.done ->
				store = new Stores.ObjectStore runtime: runtime
				transaction = new JEFRi.Transaction()
				user = runtime.build "User",
					name: "southerd"
					address: "davidsouther@gmail.com"
				user.authinfo = runtime.build "Authinfo", {}
				authinfo = user.authinfo
				transaction.add user, authinfo
				testId = user.id()
				store.persist(transaction)
				.then (transaction)->
					transaction.hasOwnProperty("entities").should.equal true
					transaction.hasOwnProperty("attributes").should.equal true
					transaction.entities.length.should.equal 2
					transaction2 = new JEFRi.Transaction()
					transaction2.add {_type:"User", user_id:testId, authinfo:{}}
					store.get(transaction2)
					.then (transaction2)->
						transaction2.hasOwnProperty("entities").should.equal true
						transaction2.hasOwnProperty("attributes").should.equal true
						transaction2.entities.length.should.equal 2
						returnedUser = if transaction2.entities[0]._type() == "User" then transaction2.entities[0] else transaction2.entities[1]
						returnedUser.user_id.should.equal testId
						returnedUser.name.should.equal "southerd"
						returnedAuth = returnedUser.authinfo
						returnedAuth._new.should.equal false #checks to make sure that the context didn't "make one up" for ya.
						done()

		it "builds, persists and then gets entity by id with multiple relationships", (done)->
			runtime.ready.done ->
				store = new Stores.ObjectStore runtime: runtime
				transaction = new JEFRi.Transaction()
				user = runtime.build "User",
					name: "southerd"
					address: "davidsouther@gmail.com"
				user.authinfo = runtime.build "Authinfo", {}
				authinfo = user.authinfo
				group = runtime.build "Group",
					name: "newyorkers"
				user.group = group
				transaction.add user, authinfo, group
				testId = user.id()
				store.persist(transaction)
				.then (transaction)->
					transaction.hasOwnProperty("entities").should.equal true
					transaction.hasOwnProperty("attributes").should.equal true
					transaction.entities.length.should.equal 3
					transaction2 = new JEFRi.Transaction()
					transaction2.add {_type:"User", user_id:testId, authinfo:{}, group:{}}
					store.get(transaction2)
					.then (transaction2)->
						transaction2.hasOwnProperty("entities").should.equal true
						transaction2.hasOwnProperty("attributes").should.equal true
						transaction2.entities.length.should.equal 3
						returnedUser = if transaction2.entities[0]._type() == "User" then transaction2.entities[0] else transaction2.entities[1]
						returnedUser.user_id.should.equal testId
						returnedUser.name.should.equal "southerd"
						returnedAuth = returnedUser.authinfo
						returnedAuth._new.should.equal false #checks to make sure that the context didn't "make one up" for ya.
						returnedGroup = returnedUser.group
						returnedGroup._new.should.equal false #checks to make sure that the context didn't "make one up" for ya.
						returnedGroup.name.should.equal "newyorkers"
						in_array = yes if returnedUser in returnedGroup.users
						in_array.should.equal true
						done()

		it "builds, persists and then gets all with relationships in one transaction", (done)->
			runtime.ready.done ->
				store = new Stores.ObjectStore runtime: runtime
				transaction = new JEFRi.Transaction()
				users = {
					"newyorkers":[
						{name: "southerd", address: "davidsouther@gmail.com", gender: "male"}
						{name: "levinea", address: "annie@levine.com", gender: "female"}
					]
					"monuhtanans":[
						{name: "portaj", address: "jonathan@jonathanporta.com", gender: "male"}
						{name: "pochaj", address: "jessicapocha@gmail.com", gender: "female"}
					]
				}
				for key,val of users
					group = runtime.build "Group", {name:key}
					for u in val
						user = runtime.build "User", u
						user.authinfo = runtime.build "Authinfo", {}
						authinfo = user.authinfo
						user.group = group
						transaction.add user, authinfo
					transaction.add group
				store.persist(transaction)
				.then (transaction)->
					transaction.hasOwnProperty("entities").should.equal true
					transaction.hasOwnProperty("attributes").should.equal true
					transaction.entities.length.should.equal 10
					transaction2 = new JEFRi.Transaction()
					transaction2.add {_type:"User", group:{}, authinfo:{}}
					store.get(transaction2)
					.then (transaction2)->
						transaction2.hasOwnProperty("entities").should.equal true
						transaction2.hasOwnProperty("attributes").should.equal true
						transaction2.entities.length.should.equal 10
						done()

		it "builds, persists and then gets all with relationships in one transaction, nested:{{{}}}", (done)->
			runtime.ready.done ->
				store = new Stores.ObjectStore runtime: runtime
				transaction = new JEFRi.Transaction()
				users = {
					"newyorkers":[
						{name: "southerd", address: "davidsouther@gmail.com", gender: "male"}
						{name: "levinea", address: "annie@levine.com", gender: "female"}
					]
					"monuhtanans":[
						{name: "portaj", address: "jonathan@jonathanporta.com", gender: "male"}
						{name: "pochaj", address: "jessicapocha@gmail.com", gender: "female"}
					]
				}
				for key,val of users
					group = runtime.build "Group", {name:key}
					for u in val
						user = runtime.build "User", u
						user.authinfo = runtime.build "Authinfo", {}
						authinfo = user.authinfo
						user.group = group
						transaction.add user, authinfo
					transaction.add group
				store.persist(transaction)
				.then (transaction)->
					transaction.hasOwnProperty("entities").should.equal true
					transaction.hasOwnProperty("attributes").should.equal true
					transaction.entities.length.should.equal 10
					transaction2 = new JEFRi.Transaction()
					transaction2.add {_type:"Group", users:{authinfo:{}}}
					store.get(transaction2)
					.then (transaction2)->
						transaction2.hasOwnProperty("entities").should.equal true
						transaction2.hasOwnProperty("attributes").should.equal true
						transaction2.entities.length.should.equal 10
						done()

		it "builds, persists and then gets an entity by key with relationships, nested.", (done)->
			runtime.ready.done ->
				store = new Stores.ObjectStore runtime: runtime
				transaction = new JEFRi.Transaction()
				users = {
					"newyorkers":[
						{name: "southerd", address: "davidsouther@gmail.com", gender: "male"}
						{name: "levinea", address: "annie@levine.com", gender: "female"}
					]
					"monuhtanans":[
						{name: "portaj", address: "jonathan@jonathanporta.com", gender: "male"}
						{name: "pochaj", address: "jessicapocha@gmail.com", gender: "female"}
					]
				}
				for key,val of users
					group = runtime.build "Group", {name:key}
					for u in val
						user = runtime.build "User", u
						user.authinfo = runtime.build "Authinfo", {}
						authinfo = user.authinfo
						user.group = group
						transaction.add user, authinfo
					transaction.add group
					testId = group.id()
				store.persist(transaction)
				.then (transaction)->
					transaction.hasOwnProperty("entities").should.equal true
					transaction.hasOwnProperty("attributes").should.equal true
					transaction.entities.length.should.equal 10
					transaction2 = new JEFRi.Transaction()
					transaction2.add {_type:"Group", group_id:testId, users:{authinfo:{}}}
					store.get(transaction2)
					.then (transaction2)->
						transaction2.hasOwnProperty("entities").should.equal true
						transaction2.hasOwnProperty("attributes").should.equal true
						transaction2.entities.length.should.equal 5
						done()

		it "builds entities with a parent->child relationship with itself and then assigns parents and children in various ways.", (done)->
			runtime.ready.done ->
				store = new Stores.ObjectStore runtime: runtime
				transaction = new JEFRi.Transaction()
				mainGroup = runtime.build "Group", {name:"Main Group"}
				mainGroup.subgroups.length.should.equal 0

				subGroup1 = runtime.build "Group", {name:"Sub Group 1"}
				subGroup2 = runtime.build "Group", {name:"Sub Group 2"}

				subGroup3 = runtime.build "Group", {name:"Sub Group 3", parent:mainGroup} #doesn't work! not sure if this should work. I don't think specs should be more than just that, a spec. If full entities are being included in a spec, I am not sure that is a good way to go.

				mainGroup.subgroups.length.should.equal 0

				subGroup4 = runtime.build "Group", {name:"Sub Group 4", parent_id:mainGroup.id()} #doesn't work prior to a persist. Build should probably be smart enough to handle this case. It will be resolved once the entity is persisted and reborn in the runtime.
				mainGroup.subgroups.length.should.equal 0

				mainGroup.subgroups = subGroup1
				mainGroup.subgroups.length.should.equal 1

				subGroup2.parent = mainGroup
				mainGroup.subgroups.length.should.equal 2 #Setting a side should set both sides. This is probably because there is only one side of the relationship defined in the context. Either, we can define both, or, just work this in as an edgecase in our muttaccs.

				done()
