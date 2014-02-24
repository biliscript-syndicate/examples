/**
 * Copyright ysle ( http://wonderfl.net/user/ysle )
 * MIT License ( http://www.opensource.org/licenses/mit-license.php )
 * Downloaded from: http://wonderfl.net/c/qGQZ
 */

var unload = $G._get('unload');
if (unload) unload();
Vector3D = ($.createVector3D()).constructor;

var screen = $.createCanvas({
            width: Player.width,
            height: Player.height,
            lifeTime: 0
});
screen.transform.matrix3D = null;
screen.x = Player.width / 2;
screen.y = Player.height / 2;

function getR(a, c) {
    return Math.sqrt(c * c - a * a);
}
var rules = [
    {r:0xff, g:0, b:0, dr:0, dg:1, db:0 },
    {r:0xff, g:0xff, b:0, dr: -1, dg:0, db:0 },
    {r:0, g:0xff, b:0, dr:0, dg:0, db: +1 },
    {r:0, g:0xff, b:0xff, dr:0, dg: -1, db:0 },
    {r:0, g:0, b:0xff, dr: +1, dg:0, db:0 },
    {r:0xff, g:0, b:0xff, dr:0, dg:0, db: -1 }
];		
function getColor(value) {
    var d = (value = value % 0x5fa) % 0xff;
    var r = rules[(value / 0xff) | 0];
    return ((r.r+r.dr*d)<<16)+((r.g+r.dg*d)<<8)+(r.b+r.db*d);
}		

var radius = 200;
var detail = 80;
var stripes = 9;
var vertices = $.toNumberVector([]);
var indices = $.toIntVector([]);
var uvtData = $.toNumberVector([]);
var projectedVertices = $.toNumberVector([]);
function init() {
    var frh = radius * 2 / (stripes * 2 +1);
    var yc = -radius;
    var rad, last, yUp, yDown, rUp, rDown, i;
			
    for (var s = 0; s < stripes; s++) {
        yUp = yc += frh ;
        yDown = yc += frh;
        rUp = getR(yUp, radius);
        rDown = getR(yDown, radius);
        i = detail*2*s;
				
        for (var c = 0; c < detail; c++) {
            rad = (2 * Math.PI) / detail * c;
            vertices.push(Math.cos(rad) * rUp, Math.sin(rad) * rUp, yUp );
            vertices.push(Math.cos(rad) * rDown, Math.sin(rad) * rDown, yDown );

            last = c == (detail - 1);
            indices.push(i + c * 2, i + c * 2 + 1, i + (last?0:c * 2 + 2));
            indices.push(i + c * 2 + 1, i +  (last?1:c * 2 + 3), i +  (last?0:c * 2 + 2));
        }
    }

    uvtData.length = indices.length;
    projectedVertices.length = vertices.length / 3 * 2;
    projectedVertices.fixed = true;
    vertices.fixed = true;
    indices.fixed = true;
    uvtData.fixed = true;
}
		
var counter = 0;
var point = $.createPoint();
var rx = 0;
var ry = 0;
var fill = true;
var wireframe = false;
var frames = 0;
var fpsText = $.createComment('', {fontsize:12, lifeTime:0});
var frameCount = 0;
var nextUpdate = getTimer() + 1000;
var lastTime = getTimer();
var matrix3D = $.createMatrix3D([]);
function render() {
    var now = getTimer();
    frameCount++;
    if (now >= nextUpdate) {
        fps = ((frameCount / (now - lastTime) * 1000 * 10) | 0) / 10;
        fpsText.text = '' + fps;
        lastTime = now;
        frameCount = 0;
        nextUpdate = getTimer() + 1000;
    }

    matrix3D.identity();
    matrix3D.prependRotation(rx+=0.5, Vector3D.X_AXIS);
    matrix3D.prependRotation(ry+=1.25, Vector3D.Y_AXIS);
    $.projectVectors(matrix3D, vertices, projectedVertices, uvtData);
    screen.graphics.clear();
    var color = getColor(counter++);
    if (wireframe)
        screen.graphics.lineStyle(0, fill?0:color, fill?0.2:1);
    if (fill)
        screen.graphics.beginFill(0xffffff);
    screen.graphics.drawTriangles(projectedVertices, indices, null, 'negative');
    if(fill)
        screen.graphics.beginFill(color);
    screen.graphics.drawTriangles(projectedVertices, indices, null, 'positive');
    screen.graphics.endFill();
}

init();
screen.addEventListener('enterFrame', render);
$G._set('unload', function(){
    screen.removeEventListener('enterFrame', render);
    ScriptManager.clearEl();
    $G._set('unload', undefined);
});
