db.runCommand({drop: "dealerships"})
db.dealerships.insert({"name":"Frank's Fords",        "affiliation":"Ford",      loc:{type: "Point", coordinates: [-114.11773681640625, 51.10682735591432]}})
db.dealerships.insert({"name":"Steve's Suzukis",      "affiliation":"Suzuki",    loc:{type: "Point", coordinates: [-114.11773681640625, 51.09144802136697]}})
db.dealerships.insert({"name":"Charlie's Chevrolets", "affiliation":"Chevrolet", loc:{type: "Point", coordinates: [-114.10400390625,    51.08282186160978]}})
db.dealerships.insert({"name":"Nick's Nissans",       "affiliation":"Nissan",    loc:{type: "Point", coordinates: [-113.98040771484375, 51.12076493195686]}})
db.dealerships.insert({"name":"Tom's Toyotas",        "affiliation":"Toyota",    loc:{type: "Point", coordinates: [-113.98040771484375, 50.93939251390387]}})
db.dealerships.ensureIndex({loc:"2dsphere", affiliation:1})

db.dealerships.find({loc: {$near: {$geometry: { type: "Point", coordinates: [-114,51]}, $maxDistance: 12000}}}).sort({name:1})

//Query returns:
//{ "_id" : ObjectId("540f3a1b6273661ad508664a"), "name" : "Charlie's Chevrolets", "affiliation" : "Chevrolet", "loc" : { "type" : "Point", "coordinates" : [  -114.10400390625,  51.08282186160978 ] } }
//{ "_id" : ObjectId("540f3a1b6273661ad508664c"), "name" : "Tom's Toyotas", "affiliation" : "Toyota", "loc" : { "type" : "Point", "coordinates" : [  -113.98040771484375,  50.93939251390387 ] } }


db.dealerships.find({ loc : { $geoWithin: { $geometry: { type: "Polygon", coordinates: [[ [-114.19052124023438, 51.12335082548444], [-114.05593872070312, 51.11904092252057], [-114.02435302734375, 51.02325750523972], [-114.1644287109375, 51.01634653617311], [-114.19052124023438, 51.12335082548444] ]]}}}}).sort({name:1})

//Query returns:
//{ "_id" : ObjectId("4e892d8c7f369ee980a3662b"), "name" : "Charlie's Chevrolets", "affiliation" : "Chevrolet", "loc" : { "lon" : 51.08282186160978, "lat" : -114.10400390625 } }
//{ "_id" : ObjectId("4e892d797f369ee980a36629"), "name" : "Frank's Fords", "affiliation" : "Ford", "loc" : { "lon" : 51.10682735591432, "lat" : -114.11773681640625 } }
//{ "_id" : ObjectId("4e892d837f369ee980a3662a"), "name" : "Steve's Suzukis", "affiliation" : "Suzuki", "loc" : { "lon" : 51.09144802136697, "lat" : -114.11773681640625 } }




db.dealerships.aggregate([{$geoNear:{near: { type: "Point", coordinates: [-114,51]},distanceField:"distance",maxDistance:12000,spherical:true}}])

//Query returns:
//{
//        "result" : [
//                {
//                        "_id" : ObjectId("540f3a1b6273661ad508664c"),
//                        "name" : "Tom's Toyotas",
//                        "affiliation" : "Toyota",
//                        "loc" : {
//                                "type" : "Point",
//                                "coordinates" : [
//                                        -113.98040771484375,
//                                        50.93939251390387
//                                ]
//                        },
//                        "distance" : 6885.127844583279
//                },
//                {
//                        "_id" : ObjectId("540f3a1b6273661ad508664a"),
//                        "name" : "Charlie's Chevrolets",
//                        "affiliation" : "Chevrolet",
//                        "loc" : {
//                                "type" : "Point",
//                                "coordinates" : [
//                                        -114.10400390625,
//                                        51.08282186160978
//                                ]
//                        },
//                        "distance" : 11747.037933848984
//                }
//        ],
//        "ok" : 1
//}
