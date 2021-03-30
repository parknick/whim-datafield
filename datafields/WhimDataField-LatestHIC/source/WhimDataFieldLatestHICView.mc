using Toybox.WatchUi;

class WhimDataFieldLatestHICView extends WatchUi.SimpleDataField {

    var whimChannel;

    // Set the label of the data field here.
    function initialize(channel) {
        SimpleDataField.initialize();
        label = "Largest HIC";
        whimChannel = channel;
    }

    // The given info object contains all the current workout
    // information. Calculate a value and return it in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info) {
        var latestHic = whimChannel.getLargestHic();

        if (latestHic == -1) {
            return "--";
        }

        return latestHic;
    }

}
