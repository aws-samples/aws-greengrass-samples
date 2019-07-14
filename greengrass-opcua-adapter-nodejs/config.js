// env var,  we can add server information here too

var userIdentity = null;
        userIdentity = {
                userName: process.env.User,
                password: process.env.pwd,
        };
module.exports = userIdentity;