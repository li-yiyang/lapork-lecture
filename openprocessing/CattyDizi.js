// CattyDizi.js --- Cat playing Dizi

// use local server host in lapork-lecture/op-host/bin/op-host

// ============ Configure =============

// diziNotes should be an array of notes to play
let diziNotes = [
    150, 200, 220, 240, 260, 300, 320
];

// diziHoleSize: size of the dizi hole
let diziHoleSize     = 20;

// diziPadding: padding of the hole
let diziPadding      = 20;
let diziPaddingLeft  = 50;
let diziPaddingRight = 20;

// cattySize

let cattySize = 100;

// ========= Global Constants =========

let diziWidth;
let diziHeight;
let diziCounts;

var diziGate;

// =========== Main Logic =============

function setup () {
    createCanvas(windowWidth, windowHeight);

    // init dizi
    diziCounts = diziNotes.length;
    diziWidth  = diziCounts * diziHoleSize + (diziCounts + 2) * diziPadding;
    diziHeight = diziHoleSize + 2 * diziPadding;

    diziGate   = 0;
}

function draw () {
    background(0);

    drawCat(width / 2, height / 2 - diziHoleSize - diziHoleSize / 2);
    drawDizi(mouseX, height * 0.52);
}

function mousePressed() {
}

function drawCat (x, y) {
    push();
    translate(x, y);

    drawingContext.shadowOffsetX = 0;
    drawingContext.shadowOffsetY = 0;
    drawingContext.shadowBlur = 30;
    drawingContext.shadowColor = 'rgba(255, 255, 255, 1)';

    noStroke();
    fill(255);

    let w    = cattySize * 1.3;
    let h    = cattySize * 0.9;
    let base = cattySize - h;
    let earH = h * 1.1;

    // head
    arc(0, -base, w, h, PI, 2 * PI, CHORD);
    rect(-w/2, -base * 2, w, 2 * base, 10);

    // ear
    triangle(-w/2, -base, -w/2, -earH-base, 0, 0);
    triangle( w/2, -base,  w/2, -earH-base, 0, 0);

    // eye
    pop();
}

function drawDizi (x, y) {
    push();
    let w = diziWidth;
    let h = diziHeight;
    let ww = w + diziPaddingLeft + diziPaddingRight;

    translate(x, y);

    drawingContext.shadowOffsetX = 0;
    drawingContext.shadowOffsetY = 0;
    drawingContext.shadowBlur = 20; // Control the blur amount
    drawingContext.shadowColor = 'rgba(255, 255, 255, 1)'; // Solid white glow color

    noStroke();
    fill(255);
    rect(- w/2 - diziPaddingLeft, - h/2, w + diziPaddingLeft + diziPaddingRight, h, h / 2);

    let diziGateVar = 0;
    for (let i = 0; i < diziCounts; i++) {
        let holeX = - w / 2 + diziPadding * (i + 2) + diziHoleSize * i;
        if (abs(holeX + x - windowWidth / 2) < (0.8 * diziPadding + diziHoleSize) / 2) {
            if (mouseIsPressed && mouseButton === LEFT) {
                fill(255, 125, 125);
                drawingContext.shadowColor = 'rgba(255, 125, 125, 0.5)';
                ellipse(holeX, 0, diziHoleSize, diziHoleSize);
                osc_msgsend('/diziFreq', diziNotes[i]);
                diziGateVar = 1;
            } else {
                fill(125, 255, 125);
                drawingContext.shadowColor = 'rgba(125, 255, 125, 0.5)';
                ellipse(holeX, 0, diziHoleSize, diziHoleSize);
            }
        } else {
            fill(0);
            drawingContext.shadowColor = 'rgba(0, 0, 0, 0.5)';
            ellipse(holeX, 0, diziHoleSize, diziHoleSize);
        }
    }

    if (diziGateVar != diziGate) {
        diziGate = diziGateVar;
        osc_msgsend('/diziGate', diziGate);
    }

    pop();
}

// Compatibility Layer

if (typeof osc_msgsend === 'undefined') {
    function osc_msgsend(addr, arg) {}
}

// CattyDizi.js ends here
