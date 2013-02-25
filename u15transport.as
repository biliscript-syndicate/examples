function createTransport() {
    function assert(name, condition) {
        if (condition === false || condition === undefined || condition === null) {
            trace('assertion', name, 'failed');
            0();
        }
    }

    //CRC-16-ANSI polynomial: x^16 + x^15 + x^2 + 1 (0xa001 LSBF/reversed)
    var CRC_TAB = [
    0x0000, 0xC0C1, 0xC181, 0x0140, 0xC301, 0x03C0, 0x0280, 0xC241,
    0xC601, 0x06C0, 0x0780, 0xC741, 0x0500, 0xC5C1, 0xC481, 0x0440,
    0xCC01, 0x0CC0, 0x0D80, 0xCD41, 0x0F00, 0xCFC1, 0xCE81, 0x0E40,
    0x0A00, 0xCAC1, 0xCB81, 0x0B40, 0xC901, 0x09C0, 0x0880, 0xC841,
    0xD801, 0x18C0, 0x1980, 0xD941, 0x1B00, 0xDBC1, 0xDA81, 0x1A40,
    0x1E00, 0xDEC1, 0xDF81, 0x1F40, 0xDD01, 0x1DC0, 0x1C80, 0xDC41,
    0x1400, 0xD4C1, 0xD581, 0x1540, 0xD701, 0x17C0, 0x1680, 0xD641,
    0xD201, 0x12C0, 0x1380, 0xD341, 0x1100, 0xD1C1, 0xD081, 0x1040,
    0xF001, 0x30C0, 0x3180, 0xF141, 0x3300, 0xF3C1, 0xF281, 0x3240,
    0x3600, 0xF6C1, 0xF781, 0x3740, 0xF501, 0x35C0, 0x3480, 0xF441,
    0x3C00, 0xFCC1, 0xFD81, 0x3D40, 0xFF01, 0x3FC0, 0x3E80, 0xFE41,
    0xFA01, 0x3AC0, 0x3B80, 0xFB41, 0x3900, 0xF9C1, 0xF881, 0x3840,
    0x2800, 0xE8C1, 0xE981, 0x2940, 0xEB01, 0x2BC0, 0x2A80, 0xEA41,
    0xEE01, 0x2EC0, 0x2F80, 0xEF41, 0x2D00, 0xEDC1, 0xEC81, 0x2C40,
    0xE401, 0x24C0, 0x2580, 0xE541, 0x2700, 0xE7C1, 0xE681, 0x2640,
    0x2200, 0xE2C1, 0xE381, 0x2340, 0xE101, 0x21C0, 0x2080, 0xE041,
    0xA001, 0x60C0, 0x6180, 0xA141, 0x6300, 0xA3C1, 0xA281, 0x6240,
    0x6600, 0xA6C1, 0xA781, 0x6740, 0xA501, 0x65C0, 0x6480, 0xA441,
    0x6C00, 0xACC1, 0xAD81, 0x6D40, 0xAF01, 0x6FC0, 0x6E80, 0xAE41,
    0xAA01, 0x6AC0, 0x6B80, 0xAB41, 0x6900, 0xA9C1, 0xA881, 0x6840,
    0x7800, 0xB8C1, 0xB981, 0x7940, 0xBB01, 0x7BC0, 0x7A80, 0xBA41,
    0xBE01, 0x7EC0, 0x7F80, 0xBF41, 0x7D00, 0xBDC1, 0xBC81, 0x7C40,
    0xB401, 0x74C0, 0x7580, 0xB541, 0x7700, 0xB7C1, 0xB681, 0x7640,
    0x7200, 0xB2C1, 0xB381, 0x7340, 0xB101, 0x71C0, 0x7080, 0xB041,
    0x5000, 0x90C1, 0x9181, 0x5140, 0x9301, 0x53C0, 0x5280, 0x9241,
    0x9601, 0x56C0, 0x5780, 0x9741, 0x5500, 0x95C1, 0x9481, 0x5440,
    0x9C01, 0x5CC0, 0x5D80, 0x9D41, 0x5F00, 0x9FC1, 0x9E81, 0x5E40,
    0x5A00, 0x9AC1, 0x9B81, 0x5B40, 0x9901, 0x59C0, 0x5880, 0x9841,
    0x8801, 0x48C0, 0x4980, 0x8941, 0x4B00, 0x8BC1, 0x8A81, 0x4A40,
    0x4E00, 0x8EC1, 0x8F81, 0x4F40, 0x8D01, 0x4DC0, 0x4C80, 0x8C41,
    0x4400, 0x84C1, 0x8581, 0x4540, 0x8701, 0x47C0, 0x4680, 0x8641,
    0x8201, 0x42C0, 0x4380, 0x8341, 0x4100, 0x81C1, 0x8081, 0x4040];

    function crc16(byteArray) {
        var crc = 0xFFFF;
        var len = byteArray.length;
        var i = 0;
        while (i < len) {
            //assert('crc16: byteArray[i]', byteArray[i] === byteArray[i | 0]);
            crc = CRC_TAB[crc & 0xFF ^ byteArray[i++]] ^ crc >> 8;
        }
        return crc;
    }

    /* Safe character range in XML is \t \n \r #x20-#xD7FF #xE000-#xFFFD
       #x20 \t may be trimmed; \r \n are banned. 
       There is a server-side silent truncation at 300 bytes.
       Unicode range [0x4000, 0x9fff] and [0xb000-0xcfff] have been manually verified to be safe.
       There may still be random "code:-3", inevitably.
       */
    function alpha2code(alpha) { //alpha must be in [0, 0x8000)
        //assert('alpha2code: alpha is legal', alpha >= 0 && alpha < 0x8000);
        return (alpha < 0x6000 ? 0x4000 : 0x5000) + alpha;
    }

    function code2alpha(code) { //code must be in [0x4000, 0x9fff] [0xb000-0xcfff]
        //assert('code2alpha: code is legal', code >= 0x4000 && code <= 0x9fff || code >= 0xb000 && code <= 0xcfff);
        return code - (code < 0xb000 ? 0x4000 : 0x5000);
    }

    function explode(packet) {
        return (packet.split('')).map(function (s) {
            return code2alpha(s.charCodeAt());
        });
    }

    function implode(numerals) {
        return String.fromCharCode.apply(null, numerals.map(alpha2code));
    }

    function mutate_raw(numerals, use_xor_key) {
        var new_xor_key = use_xor_key;
        if (use_xor_key === undefined) new_xor_key = Utils.rand(0, 0x8000);
        var xor_key = numerals[0] ^ new_xor_key;
        numerals[0] = new_xor_key;
        var len = numerals.length;
        for (var i = 1; i < len; ++i) {
            //assert('mutate_raw: numerals[i]', numerals[i] === numerals[i | 0]);
            numerals[i] ^= xor_key;
            //assert('mutate_raw: numerals[i] is legal', numerals[i] >= 0 && numerals[i] < 0x8000);
        }
        return numerals;
    }

    //take unpadded ByteArray, produce padded numeral Array
    function unpack15(byteArray) {
        var len = byteArray.length;
        var buf = 0, buffered = 0;
        var numerals = [];
        for (var i = 0; i < len; i++) {
            //assert('unpack15: byteArray[i]', byteArray[i] === byteArray[i | 0]);
            var byte = byteArray[i];
            if (buffered >= 7) {
                numerals.push(buf | byte >> buffered - 7); //15 - $buffered bits written; $buffered - 7 bits next
                buffered -= 7;
                buf = 0;
            } else {
                buffered += 8;
            }
            buf |= byte << 15 - buffered & 0x7fff;
        }
        if (buffered > 0) numerals.push(buf);
        return numerals;
    }

    //take numeral Array with padding bits, produce unpadded ByteArray
    //@padding must be < 16
    function pack15(numerals, padding) {
        //assert('pack15: padding < 16', padding < 16);
        //assert('libBitmap is loaded', Bitmap !== undefined);
        var bmd = Bitmap.createBitmapData(1, 1);
        var byteArray = bmd.getPixels(bmd.rect);
        byteArray.length = 0;
        var len = numerals.length;
        var buf = 0, buffered = 0;
        for (var i = 0; i < len; i++) {
            //assert('pack15: numerals[i]', numerals[i] === numerals[i | 0]);
            var numeral = numerals[i];
            byteArray.writeByte(buf | numeral >> buffered + 7);
            buffered += 7;
            if (buffered >= 8) {
                if (i === len - 1 && buffered <= padding)
                    break;
                byteArray.writeByte(numeral >> buffered - 8 & 0xff); //8 bits written; $buffered - 8 bits ntext
                buffered -= 8;
            }
            buf = numeral << 8 - buffered & 0xff;
            //assert('pack15: buffered < 8', buffered < 8);
        }
        return byteArray;
    }

    function bin8(dec) {
        var n = 8;
        var bin = '';
        while (n--) {
            var next = dec & 1;
            dec >>= 1;
            bin = '01'.charAt(next) + bin;
        }
        return bin;
    }

    function bin15(dec) {
        var n = 15;
        var bin = '';
        while (n--) {
            var next = dec & 1;
            dec >>= 1;
            bin = '01'.charAt(next) + bin;
        }
        return bin;
    }

    function hex(dec) {
        var hex = '';
        while (dec > 0) {
            var next = dec & 0xF;
            dec >>= 4;
            hex = '0123456789ABCDEF'.charAt(next) + hex;
        }
        return hex.length ? hex : '0';
    }

    function array_equal(a, b) {
        if (a.length != b.length) {
            trace('DEBUG array_equal: lengths differ', a.length, b.length);
            return false;
        }
        for (var i = 0; i < a.length; i++) {
            assert('array_equal', a[i] === a[i|0] && b[i] === b[i|0]);
            if (a[i] !== b[i]) {
                trace('DEBUG array_equal: differ at', i, a[i], b[i]);
                return false;
            }
        }
        return true;
    }
    function createByteArray() {
        assert('libBitmap is loaded', Bitmap !== undefined);
        var bmd = Bitmap.createBitmapData(1, 1);
        var ba = bmd.getPixels(bmd.rect);
        return ba;
    }
    function fillRandomBytes(byteArray, len) {
        byteArray.length = 0;
        while (len--) byteArray.writeByte(Utils.rand(0, 256));
        return byteArray;
    }
    var tests = {
        crc16: function () {
            var ba = createByteArray();
            ba.endian = 'littleEndian';
            for (var n = 1; n < 100; n++) {
                fillRandomBytes(ba, n);
                ba.writeShort(crc16(ba));
                if (crc16(ba) !== 0) {
                    return false;
                }
            }
            return true;
        },
        alpha2code: function () {
            for (var alpha = 0; alpha < 0x8000; alpha++) {
                var code = alpha2code(alpha);
                if (code < 0x4000 || code > 0x9fff && code < 0xb000 || code > 0xcfff) {
                    return false;
                }
                if (code2alpha(code) !== alpha) {
                    return false;
                }
            }
            return true;
        },
        code2alpha: function () {
            for (var code = 0x4000; code < 0xd000; code++) {
                if (code > 0x9fff && code < 0xb000) continue;
                var alpha = code2alpha(code);
                if (alpha < 0 || alpha >= 0x8000) {
                    return false;
                }
                if (alpha2code(alpha) !== code) {
                    return false;
                }
            }
            return true;
        },
        explode: function () {
            for (var n = 1; n < 100; n++) {
                var numerals = [];
                for (var i = 0; i < n; i++)
                numerals.push(Utils.rand(0, 0x8000) | 0);
                if (implode(explode(implode(numerals))) !== implode(numerals)) {
                    return false;
                }
            }
            return true;
        },
        unpack15: function () {
            var byteArray = createByteArray();
            for (var n = 1; n < 256; n++) {
                fillRandomBytes(byteArray, n);
                var numerals = unpack15(byteArray);
                var byteArray2 = pack15(numerals, numerals.length * 15 - byteArray.length * 8);
                if (!array_equal(byteArray, byteArray2))
                    return false;
            }
            return true;
        },
        mutate_raw: function () {
            for (var n = 1; n < 100; n++) {
                var numerals = [0];
                for (var i = 0; i < n; i++)
                    numerals.push(Utils.rand(0, 0x8000) | 0);
                var numerals2 = mutate_raw(numerals.slice());
                mutate_raw(numerals2, 0);
                if (!array_equal(numerals, numerals))
                    return false;
            }
            return true;
        }
    };
    return {
        //@packet String
        //@use_xor_key uint (optional); a static key to mutate packet; 0 for unmutation; default: random
        //@return mutated packet
        mutate: function (packet, use_xor_key) {
            return '$' + implode(mutate_raw(explode(packet.slice(1)), use_xor_key));
        },
        //@payload ByteArray (readonly); maximum length: 404
        //@use_xor_key uint; a static key to mutate packet, must be in [0, 0x8000)
        //@return the packet; String or null on error;
        //No compression inside; Ignores payload.position
        encapsulate: function (payload, use_xor_key) {
            var byteArray = clone(payload);
            byteArray.position = byteArray.length;
            byteArray.endian = 'littleEndian';
            byteArray.writeShort(crc16(byteArray));
            var numerals = unpack15(byteArray);
            var paddings = (numerals.length * 15 - byteArray.length * 8) & 0xf;
            var header = paddings;
            numerals.unshift(0, header);
            if (numerals.length > 219) {
                trace('encapsulate: payload too long', payload.length);
                return null;
            }
            return '$' + implode(mutate_raw(numerals, use_xor_key));
        },
        //@packet String
        //@return the payload; ByteArray or null on error
        //No decompression inside; Requires Bitmap
        decapsulate: function (packet) {
            if (packet.length < 4) {
                //'$' XOR_KEY RESERVED 
                trace('decapsulate: no content');
                return null;
            }
            var numerals = mutate_raw(explode(packet.slice(1)), 0);
            numerals.shift();
            var header = numerals.shift();
            var paddings = header & 0xf;
            var byteArray = pack15(numerals, paddings);
            if (crc16(byteArray) !== 0) {
                trace('decapsulate: bad checksum', crc16(byteArray));
                return null;
            }
            byteArray.length -= 2;
            return byteArray;
        },
        //tests if it works
        runtest: function () {
            var self = this; //XXX load() will change global context, $this won't survive
            load('libBitmap', function () {
                trace(self.selftest1());
                foreach(tests, function (name, exec) {
                    //trace('test', name, ':');
                    trace('test', name, exec() ? 'PASS' : 'FAIL');
                });
            });
        },
        selftest1: function () {
            var ba = createByteArray();
            for (var n = 1; n < 404; n++) {
                fillRandomBytes(ba, n);
                XOR_KEY = Utils.rand(0, 0x8000);
                var s = this.encapsulate(ba, XOR_KEY);
                if (s === null)
                    return 'selftest 1 FAIL 1';
                var ba1 = this.decapsulate(s);
                if (ba1 === null)
                    return 'selftest 1 FAIL 2';
                if (!array_equal(ba, ba1))
                    return 'selftest 1 FAIL 2a';
                var ba2 = this.decapsulate(this.mutate(s));
                if (ba2 === null)
                    return 'selftest 1 FAIL 2b';
                if (!array_equal(ba, ba2))
                    return 'selftest 1 FAIL 2c';
                var s1 = this.encapsulate(ba1, XOR_KEY);
                if (s1 === null)
                    return 'selftest 1 FAIL 3';
                if (s1 !== s)
                    return 'selftest 1 FAIL 4';
            }
            return 'selftest 1 PASS';
        },
        //measures performance
        benchmark: function () {
            function perf(name, exec, N) {
                var N = N || 100000, i;
                trace('perf', name, N);
                var idle = function () {};
                var start = getTimer();
                i = N;
                while (i--) idle();
                var idleRate = (getTimer() - start) * 1000 / N;
                start = getTimer();
                i = N;
                while (i--) exec();
                var rate = (getTimer() - start) * 1000 / N;
                trace(name, Math.round((rate - idleRate) * 1000) / 1000, 'us/op');
            }
            var ba = createByteArray();
            fillRandomBytes(ba, 404);
            var self = this;
            perf('encap', function () {
                s = self.encapsulate(ba);
            }, 100);
            perf('decap', function () {
                ba = self.decapsulate(s);
            }, 100);
            perf('crc16', function () {
                crc16(ba);
            }, 100);
            perf('explode', function () {
                explode(s);
            }, 100);
            perf('mutate', function () {
                self.mutate(s);
            }, 100);
        }
    };
}
t = createTransport();
t.runtest();
t.benchmark();

/* example
packetString = t.encapsulate(someByteArray);
//then put the packetString into the textInput

//if code:-3, ask user to press some button and then
packetString = t.mutate(packetString);

//then, resend
*/