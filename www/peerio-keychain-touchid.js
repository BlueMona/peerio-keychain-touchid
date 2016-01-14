
var exec = require('cordova/exec');

var PeerioTouchIdKeychain = {
    isFeatureAvailable: function() {
        console.log('testing availability');
        return new Promise(function(success, error) { 
            exec(success, error, 'PeerioTouchIdKeychain', 'isFeatureAvailable');
        });
    },

    saveValue: function(key, value) {
        console.log('save value to keychain');
        return new Promise(function(success, error) { 
            exec(success, error, 'PeerioTouchIdKeychain', 'saveValue', [key, value]);
        });
    },

    getValue: function(key) {
        console.log('has value in keychain');
        return new Promise(function(success, error) { 
            exec(success, error, 'PeerioTouchIdKeychain', 'getValue', [key]);
        });
    },

    deleteValue: function(key) {
        console.log('has value in keychain');
        return new Promise(function(success, error) { 
            exec(success, error, 'PeerioTouchIdKeychain', 'deleteValue', [key]);
        });
    },
};

module.exports = PeerioTouchIdKeychain;
