using Toybox.Application;

class WhimDataFieldLatestHICApp extends Application.AppBase {

    var whimChannel;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
        // Create channel object and open it
        whimChannel = new WhimChannel();
        whimChannel.open();
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
        // Close and release the channel
        whimChannel.close();
        whimChannel.release();
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [ new WhimDataFieldLatestHICView(whimChannel) ];
    }

}
