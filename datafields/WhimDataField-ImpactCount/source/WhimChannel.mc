using Toybox.Ant;
using Toybox.System;
using Toybox.WatchUi;

enum {
    UNACQUIRED,
    CLOSED,
    OPEN
}

class WhimChannel extends Ant.GenericChannel
{
    const DEVICE_NUMBER = 0;
    const DEVICE_TYPE = 23;
    const TRANS_TYPE = 0;
    const MSG_PERIOD = 8192;
    const FREQUENCY = 66;

    var impactCount = -1;
    var state = UNACQUIRED;
    var reopen = false;

    function initialize() {
        try {
            // Get the channel
            var chanAssign = new Ant.ChannelAssignment(Ant.CHANNEL_TYPE_RX_NOT_TX, Ant.NETWORK_PUBLIC);
            GenericChannel.initialize(method(:onMessage), chanAssign);

            // Channel has been acquired, set to CLOSED state
            state = CLOSED;
            // Set reopen flag to false on initialize
            reopen = false;

            // Set the configuration
            var deviceConfig = new Ant.DeviceConfig( {
                :deviceNumber => DEVICE_NUMBER,
                :deviceType => DEVICE_TYPE,
                :transmissionType => TRANS_TYPE,
                :messagePeriod => MSG_PERIOD,
                :radioFrequency => FREQUENCY } );
            GenericChannel.setDeviceConfig(deviceConfig);

            System.println( "Channel initialized" );

        } catch ( ex instanceof UnableToAcquireChannelException ) {
            System.println( "ERROR: Unable to acquire channel" );
        } catch ( ex ) {
            System.println( "ERROR: Unexpected exception in Channel.initialize(): " + ex );
        }
    }

    function open() {
        // Attempt to open channel and handle accordingly
        if( GenericChannel.open() ) {
            System.println( "Channel opened" );
            state = OPEN;
        }
        else {
            System.println( "ERROR: Unable to open channel" );
        }
    }

    function close() {
        state = CLOSED;
        GenericChannel.close();
        System.println( "Channel closed" );
    }

    function release() {
        // Release channel if one has been acquired
        if( state != UNACQUIRED ) {
            GenericChannel.release();
        }
    }

    function getImpactCount() {
        return impactCount;
    }

    function onMessage( msg ) {
        try {
            var payload = msg.getPayload();

            if (Ant.MSG_ID_BROADCAST_DATA == msg.messageId) {

                // Handle Data Page 1
                if (payload[0] == 0x01) {
                    System.println("Data Page 1 Received!");
                    impactCount = payload[1];
                }
                else {
                    System.println("Unrecognized data page received.");
                }

            } else if( Ant.MSG_ID_CHANNEL_RESPONSE_EVENT == msg.messageId ) {
                if( Ant.MSG_ID_RF_EVENT == payload[0] ) {
                    var eventCode = payload[1];

                    switch( eventCode ) {

                        case Ant.MSG_CODE_EVENT_RX_FAIL:
                            System.println( "Response event: RX_FAIL" );
                            break;

                        case Ant.MSG_CODE_EVENT_TX:
                            System.println( "Response event: EVENT_TX" );
                            break;

                        case Ant.MSG_CODE_EVENT_TRANSFER_TX_COMPLETED:
                            System.println("Response event: TRANSFER_TX_COMPLETED");
                            break;

                        case Ant.MSG_CODE_EVENT_TRANSFER_TX_FAILED:
                            System.println("Response event: TRANSFER_TX_FAILED");
                            sendResetDataCommand();
                            break;

                        case Ant.MSG_CODE_EVENT_CHANNEL_CLOSED:
                            System.println( "Response event: CHANNEL_CLOSED" );
                            checkChannelClosure();
                            if (true == reopen) {
                                reopen = false;
                                open();
                            }
                            break;

                        case Ant.MSG_CODE_EVENT_RX_FAIL_GO_TO_SEARCH:
                            System.println( "Response event: RX_FAIL_GO_TO_SEARCH" );
                            // Disconnected from sensor, set impact count to -1
                            impactCount = -1;
                            break;

                        case Ant.MSG_CODE_EVENT_RX_SEARCH_TIMEOUT:
                            System.println( "Response event: RX_SEARCH_TIMEOUT" );
                            state = CLOSED; // Channel will automatically close
                            reopen = true;  // Reopen channel when closed event is received
                            break;

                        default:
                            handleUnexpectedAntEvent( eventCode );
                            break;
                    }
                }
            }
        } catch ( ex ) {
            GenericChannel.close();
            state = CLOSED;
            System.println( "ERROR: Unexpected exception in Channel.onMessage()", ex );
            WatchUi.requestUpdate();
        }
    }

    function checkChannelClosure() {
        if( CLOSED != state ) {
            System.println( "ERROR: Channel closed unexpectedly" );
            state = CLOSED;
            WatchUi.requestUpdate();
        }
    }

    function handleUnexpectedAntEvent( eventCode ) {
        System.println( "Unhandled ANT event: " + eventCode );
        WatchUi.requestUpdate();
    }

    function sendResetDataCommand() {
        var data = new[8];
        data[0] = 0x10;
        data[1] = 0x00;
        data[2] = 0xFF;
        data[3] = 0xFF;
        data[4] = 0xFF;
        data[5] = 0xFF;
        data[6] = 0xFF;
        data[7] = 0xFF;

        var message = new Ant.Message();
        message.setPayload(data);
        GenericChannel.sendAcknowledge(message);
    }
}
