function FSAARenderer(output, factor) {
    var upscaling = $.createMatrix();
    var downscaling = $.createMatrix();
    var rendered = null, filtered = null;
    var origin = $.createPoint();
    var blurFilter = $.createBlurFilter();
    var profiling = {};

    function setBlur(radius, quality) {
        if (radius) blurFilter.blurX = blurFilter.blurY = radius;
        if (quality) blurFilter.quality = quality;
    }

    function setFactor(newFactor) {
        factor = newFactor;
        if (factor == 1) return;
        profiling.size = output.width * factor + 'x' + output.height * factor;
        upscaling.identity();
        upscaling.scale(factor, factor);
        downscaling.identity();
        downscaling.scale(1 / factor, 1 / factor);
        rendered = Bitmap.createBitmapData(output.width * factor, output.height * factor, true);
        filtered = rendered.clone();
        setBlur(factor, 1);
    }

    function render(scene) {
        if (factor == 1) {
            output.draw(scene);
            return;
        }

        var start = getTimer();
        rendered.draw(scene, upscaling);
        profiling.rendering = (getTimer() - start) + 'ms';

        start = getTimer();
        filtered.applyFilter(rendered, rendered.rect, origin, blurFilter);
        profiling.filtering = (getTimer() - start) + 'ms';

        start = getTimer();
        output.draw(filtered, downscaling, null, null, null, true);
        profiling.sampling = (getTimer() - start) + 'ms';
    }

    {
        setFactor(factor);
    }

    return {
        setFactor: setFactor,
        setBlur: setBlur,
        render: render,
        profiling: profiling
    };
}

function Shape(period) {
    var shape = $.createShape({
        lifeTime: 0
    });
    ScriptManager.popEl(shape);
    shape.transform.matrix3D = null;

    var g = shape.graphics;
    g.beginFill(0xffffff);
    g.drawRect(0, 0, 400, 400);
    g.endFill();
    g.lineStyle(1);
    for (var theta = 0; theta < 360; theta += period) {
        g.moveTo(200, 200);
        g.lineTo(200 * (1 + 0.9 * Math.cos(theta / 180 * Math.PI)), 200 * (1 + 0.9 * Math.sin(theta / 180 * Math.PI)));
    }
    g.beginFill(0, 0);
    g.drawCircle(200, 200, 192);
    g.endFill();
    return shape;
}

function Demo() {
    var bmd = Bitmap.createBitmapData(400, 400, true);
    var bmp = Bitmap.createBitmap({
        bitmapData: bmd,
        lifeTime: 0
    });
    var fsaa = FSAARenderer(bmd, 4);
    var shape = Shape(2);

    function fix(d) {
        var x = d.x, y = d.y;
        d.transform.matrix3D = null;
        d.x = x;
        d.y = y;
        if (d.hasOwnProperty('bold')) {
            d.bold = false;
            var tf = d.defaultTextFormat;
            tf.bold = false;
            d.defaultTextFormat = tf;
        }
        return d;
    }

    var result = fix($.createComment('test', {lifeTime: 0, x: 400, y: 200, fontsize: 12}));
    function update() {
        fsaa.render(shape);
        var str = '';
        foreach(fsaa.profiling, function(k, v) {
            str += k + ': ' + v + '\n';
        });
        result.text = str;
    }


    bmp.transform.matrix3D = null;
    bmp.smoothing = false;
    bmp.pixelSnapping = "never";

    var period = fix($.createComment('line period: 2', {x: 400, y: 30, fontsize: 12, lifeTime: 0}));
    [1, 2, 3, 4].forEach(function (e) {
        fix($.createButton({text: e + '', x: 400 + (e - 1) * 12, y: 50, width: 12, height: 10, lifeTime: 0,
            onclick: function () {
                period.text = 'line period: ' + e;
                shape = Shape(e);
                update();
            }
        }));
    });

    var radius = fix($.createComment('blur radius: 4', {x: 400, y: 60, fontsize: 12, lifeTime: 0}));
    [1, 2, 3, 4, 5, 6, 7, 8].forEach(function (e) {
        fix($.createButton({text: e + '', x: 400 + (e - 1) * 12, y: 80, width: 12, height: 10, lifeTime: 0,
            onclick: function () {
                radius.text = 'blur radius: ' + e;
                fsaa.setBlur(e);
                update();
            }
        }));
    });

    var quality = fix($.createComment('blur quality: 1', {x: 400, y: 90, fontsize: 12, lifeTime: 0}));
    [1, 2, 3, 4].forEach(function (e) {
        fix($.createButton({text: e + '', x: 400 + (e - 1) * 12, y: 110, width: 12, height: 10, lifeTime: 0,
            onclick: function () {
                quality.text = 'blur quality: ' + e;
                fsaa.setBlur(undefined, e);
                update();
            }
        }));
    });

    var factor = fix($.createComment('FSAA factor: 4', {x: 400, y: 0, fontsize: 12, lifeTime: 0}));
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].forEach(function (e) {
        fix($.createButton({text: e + '', x: 400 + (e - 1) * 12, y: 20, width: 12, height: 10, lifeTime: 0,
            onclick: function () {
                factor.text = 'FSAA factor: ' + e;
                radius.text = 'blur radius: ' + e;
                quality.text = 'blur quality: 1';
                fsaa.setFactor(e);
                update();
            }
         }));
    });

    update();
}
load('libBitmap', function () {
    ScriptManager.clearEl();
    Demo();
});