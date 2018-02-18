// iOS 10 Native Speech Recognition Cordova Plugin
// (cc) 2017 Jam Zhang & Antony Zhu
//
// Usage
// cordova.plugins.Speech.startDictation()
// cordova.plugins.Speech.stopDictation()

//var exec = require('cordova/exec');
//
//exports.coolMethod = function(arg0, success, error) {
//    exec(success, error, "BLSpeechRecognition", "coolMethod", [arg0]);
//};

var cordova = require('cordova'),
    channel = require('cordova/channel'),
    exec = require('cordova/exec');

var Speech = function() {
    this.channels = {
        'SyncContact': channel.create('SyncContact'),
        'UpdateUserWord': channel.create('UpdateUserWord'),
        'SpeechError': channel.create('SpeechError'),
        'SpeechResults': channel.create('SpeechResults'),
        'VolumeChanged': channel.create('VolumeChanged'),
        'SpeechBegin': channel.create('SpeechBegin'),
        'SpeechEnd': channel.create('SpeechEnd'),
        'SpeechCancel': channel.create('SpeechCancel'),
        'SpeakCompleted': channel.create('SpeakCompleted'),
        'SpeakBegin': channel.create('SpeakBegin'),
        'SpeakProgress': channel.create('SpeakProgress'),
        'SpeakPaused': channel.create('SpeakPaused'),
        'SpeakResumed': channel.create('SpeakResumed'),
        'SpeakCancel': channel.create('SpeakCancel'),
        'BufferProgress': channel.create('BufferProgress')
    };
    this.init();
    this.msg = "";
};

Speech.prototype = {

    _eventHandler: function(info) {
        if (info.event in this.channels) {
            this.channels[info.event].fire(info);
        }
    },

    addEventListener: function(event, f, c) {
        if (event in this.channels) {
            this.channels[event].subscribe(f, c || this);
        }
    },

    removeEventListener: function(event, f) {
        if (event in this.channels) {
            this.channels[event].unsubscribe(f);
        }
    },

    init: function() {
        // closure variable for local function to use
        var speech = this;

        // the callback will be saved in the session for later use
        var callback = function(info) {
            speech._eventHandler(info);
        };
        exec(callback, callback, 'Speech', 'login', []);
        this.addEventListener('SpeechResults', parseResults);
        this.addEventListener('SpeechError', parseError);
        this.addEventListener('VolumeChanged', parseVolume);

        function parseResults( e ) {
            if (e && e.results && e.results.length) { // Heard something
                if(typeof speech.onResult === 'function') speech.onResult(e.results);
            }
        }
        
        function parseError( e ) {
            console.error('parseError', e);
        }
        
        function parseVolume( e ) {
//            console.log('parseVolume', e);
            if(typeof speech.onVolume === 'function') {
                speech.onVolume( e.volume );
            }
        }
        
    },

    // Method to start dictation
    // Dictation ends after a short break after speech, or about 1 seconds of silence
    // @param onResult (function) Callback invoked when a speech result is recognized
    // @param options (object)
    // - language (string) Locale of speech language
    // Supported locale identifiers are
    // "nl-NL","es-MX","zh-TW","fr-FR","it-IT","vi-VN","fr-CH","en-ZA","ca-ES","ko-KR","es-CL","ro-RO",
    // "en-PH","en-CA","en-SG","en-IN","en-NZ","it-CH","fr-CA","hi-IN","da-DK","de-AT","pt-BR",
    // "yue-CN","zh-CN","sv-SE","hi-IN-translit","es-ES","hu-HU","ar-SA","fr-BE","en-GB","ja-JP",
    // "zh-HK","fi-FI","tr-TR","nb-NO","en-ID","en-SA","pl-PL","id-ID","ms-MY","el-GR",
    // "cs-CZ","hr-HR","en-AE","he-IL","ru-RU","wuu-CN","de-CH","en-AU","de-DE","nl-BE","th-TH","pt-PT",
    // "sk-SK","en-US","en-IE","es-CO","hi-Latn","uk-UA","es-US"
    startDictation: function(onResult, options) {
        console.log('Speech.startDictation');
        this.isListening = true;
        if (typeof options == 'undefined') options = {};
        if (!options.language) options.language = 'en-US';
        this.onStart = options.onStart; // (function) Callback on listening start
        this.onResult = onResult; // (function) Callback on speech recognition result
        this.onError = options.onError; // (function) Callback on error
        this.onVolume = options.onVolume; // (function) Callback on input volume change
        this.continuous = options.continuous; // (boolean) If automatically start listening after previous recognition
        this.showUI = options.showUI; // Show iFly buil-in UI overlay
        this.showPunctuation = options.showPunctuation; // Recognize punctuation in speech
        exec(null, null, 'Speech', 'startListening', [{language: options.language}]);
        if(typeof this.onStart === 'function') this.onStart();
    },

    stopDictation: function() {
        this.isListening = false;
//        clearTimeout(this.timeoutID);
        exec(null, null, 'Speech', 'stopListening', []);
    },

};

module.exports = new Speech();
