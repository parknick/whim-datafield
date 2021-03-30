using Toybox.WatchUi;

class WhimDataFieldImpactCountView extends WatchUi.SimpleDataField {

    var whimChannel;

    // Set the label of the data field here.
    function initialize(channel) {
        SimpleDataField.initialize();
        label = "WHIM Impacts";
        whimChannel = channel;
    }

    // The given info object contains all the current workout
    // information. Calculate a value and return it in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info) {
        var impactCount = whimChannel.getImpactCount();

        if (impactCount == -1) {
            return "--";
        }

        return impactCount;
    }

}
