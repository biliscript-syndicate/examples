/**
 * Copyright shapevent ( http://wonderfl.net/user/shapevent )
 * MIT License ( http://www.opensource.org/licenses/mit-license.php )
 * Downloaded from: http://wonderfl.net/c/feCe
 */
var unload = $G._get('unload');
if (unload) unload();
Vector3D = ($.createVector3D()).constructor;

var verts = $.toNumberVector([]);
var pVerts = $.toNumberVector([]);
var indices = $.toIntVector([]);
var uvts = $.toNumberVector([]);
var sortedIndices = $.toIntVector([]);
var faces = [];
var tex;
var render;
var proj;
var BPM = 128;
var grad;

function init() {
    var quadNum = 300;

    var m = $.createMatrix3D([]);
    var quad = $.toNumberVector([-10, -10, 0,
                                 10, -10, 0,
                                 -10, 10, 0,
                                 10, 10, 0]);

    var transQuad = $.toNumberVector([]);
    var inc = 0;
    for (var i = 0; i < quadNum; i++) {
        m.identity();
        var s = (((Math.random()*50)|0) == 1) ? 2 + Math.random()*2 : 0.1 + Math.random() * 2;
        m.appendScale(s, s, 1);
        m.appendRotation(90, Vector3D.Y_AXIS);
        var mult = 100 + Math.random()*200;
        m.appendTranslation(mult, 0, 0);
        m.appendRotation(Math.random()*360, Vector3D.X_AXIS);
        m.appendRotation(Math.random()*360, Vector3D.Y_AXIS);
        m.appendRotation(Math.random()*360, Vector3D.Z_AXIS);
        m.transformVectors(quad, transQuad);
        verts = verts.concat(transQuad);
        faces.push($.createVector3D(), $.createVector3D());
        var i4 = i * 4;
        indices.push(0 + i4, 1 + i4, 2 + i4,
                     1 + i4, 3 + i4, 2 + i4);
        mult /= 300;
        uvts.push(mult, mult, 0,
                  mult + 0.1, mult, 0,
                  mult, mult - 0.1, 0,
                  mult + 0.1, mult + 0.1, 0);
    }

    //texture
    tex = Bitmap.createBitmapData(400, 400, false, 0x000000);
    grad = $.createShape({lifeTime:0, parent:{addChild:function(){}}});
    var mat = $.createGradientBox(400, 400, 0, 0, 0);
    grad.graphics.beginGradientFill('linear', [0xFFFFFF,0x002244], [1, 1], [100, 255], mat);
    grad.graphics.drawRect(0,0,400,400);
    tex.draw(grad);

    render = $.createShape({lifeTime:0});
    render.transform.matrix3D = null;//huge performance impact here
    render.x = Player.width / 2;
    render.y = Player.height / 2;

    verts.fixed = true;
    pVerts.length = verts.length / 3 * 2;
    pVerts.fixed = true;
    indices.fixed = true;
    uvts.fixed = true;
    sortedIndices.length = indices.length;
    sortedIndices.fixed = true;

    var persp = clone($.root.transform.perspectiveProjection);
    persp.fieldOfView = 45;
    proj = persp.toMatrix3D();
}
init();

var fpsText = $.createComment('', {fontsize:12, lifeTime:0});
var frameCount = 0;
var nextUpdate = getTimer() + 1000;
var lastTime = getTimer();
var m = $.createMatrix3D([]);

var dx = 0;
var dy = 0;

function onLoop(e) {
    var now = getTimer();
    frameCount++;
    if (now >= nextUpdate) {
        fps = ((frameCount / (now - lastTime) * 1000 * 10) | 0) / 10;
        fpsText.text = '' + fps;
        lastTime = now;
        frameCount = 0;
        nextUpdate = getTimer() + 1000;
    }
    
    dx += 0.1;
    dy += 0.2;
    m.identity();
    m.appendRotation(dy, Vector3D.X_AXIS);
    m.appendRotation(dx, Vector3D.Y_AXIS);
    m.appendTranslation(0, 0, 300);
    m.append(proj);
    
    //periodic camera vibration
    var time = getTimer() / 1000;
    var amp = 0.01;
    var freq = BPM / 60 / 4;
    var phase = 0;
    var scale = 1 + amp * Math.pow(Math.sin(freq * 2 * Math.PI * time + phase), 256);
    m.appendScale(scale, scale, scale);
    
    $.projectVectors(m, verts, pVerts, uvts);

    //z-sorting
    var inc = 0;
    for (var i = 0; i < indices.length; i += 3){
        var face = faces[inc++];
        face.x = indices[0|i];
        face.y = indices[0|(i + 1)];
        face.z = indices[0|(i + 2)];
        face.w = uvts[0|(face.x*3 + 2)] + uvts[0|(face.y*3 + 2)] + uvts[0|(face.z*3 + 2)];
    }
    faces.sortOn("w", 16);
    inc = 0;
    for (var i = 0; i < faces.length; i++){
        var face = faces[i];
        sortedIndices[inc++] = face.x;
        sortedIndices[inc++] = face.y;
        sortedIndices[inc++] = face.z;
    }

    render.graphics.clear();
    render.graphics.beginBitmapFill(tex, null, false, false);
    render.graphics.drawTriangles(pVerts, sortedIndices, uvts, 'negative');
    render.graphics.drawTriangles(pVerts, sortedIndices, uvts, 'positive');
    render.graphics.endFill();
}
render.addEventListener('enterFrame', onLoop);
$G._set('unload', function(){
    render.removeEventListener('enterFrame', onLoop);
    ScriptManager.clearEl();
    $G._set('unload', undefined);
});
