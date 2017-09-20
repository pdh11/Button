// Copyright (c) 2015 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT
//
// Description: Debounced button press with callbacks

class Button {
    static version = [1, 2, 0];

    static NORMALLY_HIGH = 1;
    static NORMALLY_LOW = 0;

    _pin = null;
    _polarity = null;
    _state = null;
    _transition = null;
    _timer = null;
    _pressCallback = null;
    _releaseCallback = null;

    constructor(pin, pull, polarity = null, pressCallback = null, releaseCallback = null) {
        _pin = pin;

        if (polarity == null) {
            if (pull == DIGITAL_IN_PULLDOWN || pull == DIGITAL_IN_WAKEUP) polarity = NORMALLY_LOW;
            else polarity = NORMALLY_HIGH;
        }

        _polarity = polarity;
        _pressCallback = pressCallback;
        _releaseCallback = releaseCallback;

        _pin.configure(pull, _checkState.bindenv(this));
    }

    function onPress(cb=null) {
        _pressCallback = cb;
        return this;
    }

    function onRelease(cb=null) {
        _releaseCallback = cb;
        return this;
    }

    /******************** PRIVATE FUNCTIONS (DO NOT CALL) ********************/
    function _inDebouncePeriod() {
        if (_transition == null) {
            return false;
        }
        return (hardware.millis() - _transition) < 10;
    }
    
    function _checkState() {
        if (_inDebouncePeriod()) {
            if (_timer == null) {
                _timer = imp.wakeup(0.010, _checkState.bindenv(this));
            }
            return;
        }
        if (_timer != null) {
            imp.cancelwakeup(_timer);
        }
        _timer = null;
        local state = _pin.read();
        if (state == _state) {
            return;
        }
        _state = state;
        _transition = hardware.millis();
        if (state == _polarity) {
            if (_releaseCallback != null) {
                _releaseCallback();
            }
        } else {
            if (_pressCallback != null) {
                _pressCallback();
            }
        }
    }
}
