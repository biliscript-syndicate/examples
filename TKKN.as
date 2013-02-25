/*
TKKN@bilibili.tv
source: http://jsfiddle.net/%6Eecrofantasia/eD6hj/
origin: http://homepage1.nifty.com/bee/tk/

change:
20121227: adapted to the new player (loaderInfo was blocked)
20130125: fps is 60 now, was 24.
*/
var Keyboard = {
    A: 65,
    S: 83,
    W: 87,
    D: 68
};
/*
str must only contain A-Za-z0-9\+\/ and CR and/or LF
*/
function extract(str) {
    var bytes = clone($G._('byteArray'));
    var lookup = $G._('base64DecodeLookupTable');
    if (!lookup) {
        lookup = [];
        for (var n = 0; n < 256; n++)
            lookup[n] = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'.indexOf(String.fromCharCode(n));
        $G._set('base64DecodeLookupTable', lookup);
    }
    str = (str.split('\n')).join('');
    str = (str.split('\r')).join('');
    var c1, c2, c3, c4;
    var i = 0, out = 0;
    var len = str.length;
    
    bytes.writeUTFBytes(str);
    while (i < len) {
        c1 = lookup[bytes[i++] ^ 0];
        c2 = lookup[bytes[i++] ^ 0];
        bytes[out++] = (c1 << 2) | ((c2 & 0x30) >> 4);
        c3 = lookup[bytes[i++] ^ 0];
        if (c3 == -1) break;//was '='
        bytes[out++] = ((c2 & 0x0f) << 4) | ((c3 & 0x3c) >> 2);
        c4 = lookup[bytes[i++] ^ 0];
        if (c4 == -1) break;//was '='
        bytes[out++] = ((c3 & 0x03) << 6) | c4;
    }
    bytes.length = out;
    bytes.inflate();
    return bytes;
}
function loadBitmapData(width, height, bytes) {
    var bmd = Bitmap.createBitmapData(width, height);
    bmd.setPixels(bmd.rect, bytes);
    return bmd;
}
function fixz(displayObject) {
    var x = displayObject.x;
    var y = displayObject.y;
    displayObject.transform.matrix3D = null;
    displayObject.x = x;
    displayObject.y = y;
    return displayObject;
}

var RAW_bilitv = '
tVQ7iFpREHUJ225lGRbrhRRhd+OTIDa2uoKKCPbCFoIobKHyiM//Dz+oqPhDiYI2amdqUWSLNKks
7axTBBacnbnwHupm/RBzYODduXPPnZk358pkp+OD2Wx+9Pl8sjPhR7Vazfd6vWNiH+fzeW88Hr+3
b+33+3+Q7+LIuy9LpVI6kUhArVb7tsN71W63IZVKXUcikX0cT5PJ5L7VanHZbJYLBAJ3TqdT63a7
fwuC8Iy+20ajcZvJZGa4/u5yub5gDIut1+sc3kH2cTabiXxQLpehWCxCLBYDPAf5fF6yQqEAeJby
gmg0CpibZKFQCJLJJPA8LzSbTYmP6vtH8NgniQ/rYE6TybTXrFYrWCwWwHlhRj6VSsX4crmcxBcM
BhkfxZ8KrVbL+LBPEh/1QcxPhMPhALlcvnU2Ho+DQqHY8imVyoN8arV6b070307hI3S7Xenbbre/
y30sH/WdUKlUWI+WyyUYjUZYLBZH89lstq1Yg8EAOp2OfaP+/9oHjUbzhg/
nne3p9fqDM7NrHMe9
mRea8XPOM+kN12wOsfZ1Op3e0tyu0f3hcHhNmiN9ot74Db19nU6nHOq0gj1ar1Yr6tWNqPcd+4z+
X16vl3J68Xg8n7BOf6fTedh4D0Q8DAaDn/hWXA+Hw33vkR/3AeOE0Wgk+894BQ==';

var RAW_bullet = 'Y2BgYPj/H4IZ4GwwgItD2EDcgKQGygYA';

var Array_achievements = '
Lc9BLwNBFAfwVOpRsSJWJOvAQSQuvTg7O/sQPoTjtkzaXavKRrVa0tIqUYtaNVnUl5k3M/0W5m0k
c5jfm5n3f5PLZ3LTmewUWJLfmUXIgoVvFd08JgDYqvIo33v4GZNnwZYtT/tFGZ6Q58DG11NkHnbT
83mwBb9Cv4NndfICWCqI8blKWARHjxg+FHR4rYInKi2BpQ9/pBcSls0Y7RKyD8KKSfJd2XrBiJFX
zc1CIJKEsAaW4CFGI8KGGbjbR14mbJkeFw3Bvwj5NNAEoN/Ubtpm21xmRzpOM3bAUcmt9ob0p/45
lXZhXQ0GgrsTtyjb3/+v9sCR5bqsXeJ9TQ3HVNqHGdW7od0BbFLKb0lHYx11BPcnjeof';

function createText(text, config) {
    var self = fixz($.createComment(text, {
        y: config.y || 0,
        fontsize: config.fontsize || 14,
        lifeTime: 0,
        parent: config.parent //must be non-null
    }));

    self.visible = config.visible || false;
    self.autoSize = config.align || 'center';
    self.width = config.parent.width;
    self.textColor = 0xff0000;

    self.filters = [$.createColorMatrixFilter([0, -1, 0, 0, 255,
                 0, -1, 0, 0, 255,
                 0, -1, 0, 0, 255,
                 0, 0, 0, 1, 0])];

    self.selectable = true;
    self.mouseEnabled = true;

    if (config.bold !== true) {
        var tf = self.defaultTextFormat;
        tf.bold = false;
        self.defaultTextFormat = tf;
        self.setTextFormat(tf);
    }

    return self;
}

function setFontSize(t, size) {
    var tf = t.defaultTextFormat;
    tf.size = size;
    t.defaultTextFormat = tf;
    t.setTextFormat(tf);
}

function fillRect(g, x, y, width, height, color) {
    g.graphics.beginFill(color);
    g.graphics.drawRect(x, y, width, height);
    g.graphics.endFill();
}

function createGame() {
    var width = 320;
    var height = 240;

    var self = {
        canvas: fixz($.createCanvas({
            x: Math.round((Player.width - width) / 2),
            y: Math.round((Player.height - height) / 2),
            lifeTime: 0
        })),
        playerWidth: Player.width,
        playerHeight: Player.height
    };

    self.border = fixz($.createShape({x: -1, y:-1, lifeTime: 0, parent: self.canvas}));
    fillRect(self.border, 0, 0, width + 2, height + 2, 0xffffff);
    self.background = fixz($.createShape({lifeTime: 0, parent: self.canvas}));
    //fillRect(self.background, self.canvas.x - 1, self.canvas.y - 1, width + 2, height + 2, 0xffffff);
    fillRect(self.background, 0, 0, width, height, 0);
    self.titleText = createText('特训', {y: 40, fontsize: 96, bold: true, parent: self.canvas});
    self.subtitleText = createText('', {y: 40 + 96 + 20, fontsize: 14, parent: self.canvas});
    self.topText = createText('根据你的训练表现，兹授予你', {align: 'left', parent: self.canvas});
    self.achievementText = createText('', {bold: true, parent: self.canvas});
    self.bottomText = createText('职称，望再接再厉。A键返回开始。', {y: height - 20, align: 'right', parent: self.canvas});

    self.keyDown = [];

    self.textureAircraft = null;
    self.textureBullet = null;
    self.entityLayer = null;
    self.aircraftAABBOffset = $.createPoint(3, 7);
    self.bulletAABBOffset = $.createPoint(2, 2);

    self.reset = function() {
        self.gameState = 'loading';
        self.bullets = [];
        self.survivedFrames = 0;
        self.finishedBullets = 0;
        self.aircraftAABB.x = width / 2;
        self.aircraftAABB.y = height / 2;
        self.subtitleText.text = '控制: W A S D\n开始: Space';
        self.startTime = 0;
        //takeFocus();
    };
    self.mainLoop = function() {
        var selfIndex = $.root.getChildIndex(self.canvas);
        if (selfIndex != $.root.numChildren - 1)
            $.root.swapChildrenAt(selfIndex, $.root.numChildren - 1);
        if (self.playerWidth != Player.width || self.playerHeight != Player.height) {
            self.canvas.x = Math.round((Player.width - width) / 2),
            self.canvas.y = Math.round((Player.height - height) / 2),
            self.playerWidth = Player.width;
            self.playerHeight = Player.height;
        }
        self.background.visible = true;
        self.canvas.visible = true;
        if (self.gameState == 'end' && self.keyDown[Keyboard.A ^ 0]) {
            self.reset();
            Player.seek(0);
            Player.pause();
            return;
        }
        if (Player.state == 'playing' && self.gameState == 'loading') {
            self.gameState = 'playing';
            self.startTime = getTimer();
        }
        if (Player.state == 'playing' && self.gameState == 'over') {
            self.gameState = 'end';
            self.entityLayer.fillRect(self.entityLayer.rect, 0);
            self.achievements.some(function(a) {
                self.achievementText.text = a[1];
                return self.survivedFrames / 60 <= a[0];
            });
            setFontSize(self.achievementText, 280 / self.achievementText.text.length);
            self.achievementText.y = Math.round((height - self.achievementText.height) / 2);
        }
        self.titleText.visible = self.gameState == 'loading';
        self.subtitleText.visible = self.gameState == 'loading' || self.gameState == 'over';
        self.topText.visible = self.gameState == 'end';
        self.achievementText.visible = self.gameState == 'end';
        self.bottomText.visible = self.gameState == 'end';
        if (Player.state != 'playing' || self.gameState != 'playing') return;

        var elapsed = (getTimer() - self.startTime) / 1000;
        self.survivedFrames++;
        self.entityLayer.lock();

        self.entityLayer.fillRect(self.entityLayer.rect, 0);

        var speed = (1 + elapsed / 120)/* 20130125: fps=60 now, was 24. * 60 / 24*/;
        var me = self.aircraftAABB;
        var dx = 0;
        var dy = 0;
        if (self.keyDown[Keyboard.W ^ 0]) dy -= speed;
        if (self.keyDown[Keyboard.S ^ 0]) dy += speed;
        if (self.keyDown[Keyboard.A ^ 0]) dx -= speed;
        if (self.keyDown[Keyboard.D ^ 0]) dx += speed;
        me.offset(dx, dy);
        if (me.left < 0) me.offset(-me.left, 0);
        if (me.right > width) me.offset(width - me.right, 0);
        if (me.top < 0) me.offset(0, -me.top);
        if (me.bottom > height) me.offset(0, height - me.bottom);
        self.entityLayer.copyPixels(self.textureAircraft, self.textureAircraft.rect, me.topLeft.subtract(self.aircraftAABBOffset), null, null, true);

        while (self.bullets.length < 40 + elapsed) {
            var pos;
            if (Math.random() > 0.5) {
                pos = $.createPoint(Utils.rand(-20, 20), Utils.rand(-20, height + 20));
                if (pos.x > 0) pos.x += width;
            } else {
                pos = $.createPoint(Utils.rand(-20, width + 20), Utils.rand(-20, 20));
                if (pos.y > 0) pos.y += height;
            }
            var target = $.createPoint(Utils.rand(me.x - 50, me.x + 50), Utils.rand(me.y - 50, me.y + 50));
            var vel = target.subtract(pos);
            vel.normalize(speed);
            self.bullets.push({
                pos: pos,
                vel: vel,
                life: 0
            });
        }
        self.finishedBullets += self.bullets.length;
        self.bullets = self.bullets.filter(function(bullet) {
            bullet.pos.offset(bullet.vel.x, bullet.vel.y);
            bullet.life++;
            if (me.containsPoint(bullet.pos)) {
                self.gameState = 'over';
                var playerTime = Player.time;
                var time = ((self.survivedFrames / 6) ^ 0) * 100 + (Player.time ^ 0) % 100;
                var timestr = ((time / 1000) ^ 0) + '.' + ((time % 1000) ^ 0);
                self.subtitleText.text = '避弹: ' + self.finishedBullets + '\n存活: ' + timestr + '\n帧率: ' + ((self.survivedFrames / elapsed) ^ 0) + '\n按Space继续';
                Player.pause();
            }
            self.entityLayer.copyPixels(self.textureBullet, self.textureBullet.rect, bullet.pos.subtract(self.bulletAABBOffset), null, null, true);
            return bullet.life < 100 || self.entityLayer.rect.containsPoint(bullet.pos);
        });
        self.finishedBullets -= self.bullets.length;

        self.entityLayer.unlock();
    };

    self.go = function() {
        Player.keyTrigger(function(keyCode) {
            self.keyDown[keyCode] = true;
        }, 2147483647);
        Player.keyTrigger(function(keyCode) {
            self.keyDown[keyCode] = false;
        }, 2147483647, true);

        self.aircraftAABB = Bitmap.createRectangle(0, 0, 14, 8);
        self.achievements = (extract(Array_achievements)).readObject();
        self.textureBullet = loadBitmapData(4, 4, extract(RAW_bullet));
        self.textureAircraft = loadBitmapData(20, 20, extract(RAW_bilitv));
        self.entityLayer = Bitmap.createBitmapData(width, height, true, 0);
        self.canvas.addChild(Bitmap.createBitmap({bitmapData: self.entityLayer, lifeTime: 0}));
        self.reset();
        self.canvas.addEventListener('enterFrame', self.mainLoop);
    };
    return self;
}
/*function stealPlayerHolder(e) {
    if (e.relatedObject) {
        //$G._set('playerHolder', e.relatedObject);
        //$.root.removeEventListener('focusOut', stealPlayerHolder);
        //$.root.removeEventListener('focusIn', stealPlayerHolder);
        trace(e.type, e.target, e.relatedObject);
    }
}
//$.root.addEventListener('focusOut', stealPlayerHolder);
//$.root.addEventListener('focusIn', stealPlayerHolder);
*/
if ($G._get('gameInstance') === undefined) {
    Player.seek(0);
    Player.pause();
    var game = createGame();
    $G._set('gameInstance', game);
    var loadingText = createText('载入…', {parent: $.root});
    loadingText.visible = true;
    var timerLoadTimeout = timer(function() {
        loadingText.text = '位图库载入失败，请刷新重试或者检查网络连接。';
    }, 3000);
    load('libBitmap', function() {
        clearTimeout(timerLoadTimeout);
        loadingText.text = '';
        loadingText.visible = false;
        var bmd = Bitmap.createBitmapData(1, 1);
        $G._set('byteArray', bmd.getPixels(bmd.rect));
        ($G._('byteArray')).clear();
        game.go();
    });
}
/*
