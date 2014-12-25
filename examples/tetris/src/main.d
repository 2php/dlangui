// Written in the D programming language.

/**
This app is a Tetris demo for DlangUI library.

Synopsis:

----
	dub run dlangui:tetris
----

Copyright: Vadim Lopatin, 2014
License:   Boost License 1.0
Authors:   Vadim Lopatin, coolreader.org@gmail.com
 */
module main;

import dlangui.all;
import dlangui.dialogs.dialog;
import dlangui.dialogs.filedlg;
import dlangui.dialogs.msgbox;
import dlangui.graphics.drawbuf;
import std.stdio;
import std.conv;
import std.utf;
import std.random;


mixin APP_ENTRY_POINT;

Widget createAboutWidget()
{
	LinearLayout res = new VerticalLayout();
	res.padding(Rect(10,10,10,10));
	res.addChild(new TextWidget(null, "DLangUI Tetris demo app"d));
	res.addChild(new TextWidget(null, "(C) Vadim Lopatin, 2014"d));
	res.addChild(new TextWidget(null, "http://github.com/buggins/dlangui"d));
	Button closeButton = new Button("close", "Close"d);
	closeButton.onClickListener = delegate(Widget src) {
		Log.i("Closing window");
		res.window.close();
		return true;
	};
	res.addChild(closeButton);
	return res;
}

/// Cell offset
struct FigureCell {
    // horizontal offset
    int dx;
    // vertical offset
    int dy;
    this(int[2] v) {
        dx = v[0];
        dy = v[1];
    }
}

/// Single figure shape for some particular orientation - 4 cells
struct FigureShape {
    /// by cell index 0..3
    FigureCell[4] cells; 
    /// lowest y coordinate - to show next figure above cup
    int extent;
    /// upper y coordinate - initial Y offset to place figure to cup
    int y0;
    this(int[2] c1, int[2] c2, int[2] c3, int[2] c4) {
        cells[0] = FigureCell(c1);
        cells[1] = FigureCell(c2);
        cells[2] = FigureCell(c3);
        cells[3] = FigureCell(c4);
        extent = y0 = 0;
        for (int i = 0; i < 4; i++) {
            if (extent > cells[i].dy)
                extent = cells[i].dy;
            if (y0 < cells[i].dy)
                y0 = cells[i].dy;
        }
    }
}

struct Figure {
    FigureShape[4] shapes; // by orientation
    this(FigureShape[4] v) {
        shapes = v;
    }
}

const Figure[6] FIGURES = [
    //   ##     ####
    // 00##       00##
    // ##       
    Figure([FigureShape([0, 0], [1, 0], [1, 1],  [0, -1]),
            FigureShape([0, 0], [0, 1], [-1, 1], [1, 0]),
            FigureShape([0, 0], [1, 0], [1, 1],  [0, -1]),
            FigureShape([0, 0], [0, 1], [-1, 1], [1, 0])]),
    // ##         ####
    // 00##     ##00
    //   ##     
    Figure([FigureShape([0, 0], [1, 0], [0, 1],  [1, 1]),
            FigureShape([0, 0], [0, 1], [1, 1],  [-1, 0]),
            FigureShape([0, 0], [1, 0], [0, 1],  [1, 1]),
            FigureShape([0, 0], [0, 1], [1, 1],  [-1, 0])]),
    //            ##        ##      ####
    // ##00##     00    ##00##        00
    // ##         ####                ##
    Figure([FigureShape([0, 0], [1, 0], [-1,0],  [-1,-1]),
            FigureShape([0, 0], [0, 1], [0,-1],  [ 1,-1]),
            FigureShape([0, 0], [1, 0], [-1,0],  [1, 1]),
            FigureShape([0, 0], [0, 1], [-1,1],  [0,-1])]),
    //            ####  ##            ##
    // ##00##     00    ##00##        00
    //     ##     ##                ####    
    Figure([FigureShape([0, 0], [1, 0], [-1,0],  [ 1, 1]),
            FigureShape([0, 0], [0, 1], [0,-1],  [ 1, 1]),
            FigureShape([0, 0], [1, 0], [-1,0],  [-1, 1]),
            FigureShape([0, 0], [0, 1], [-1,-1], [0, -1])]),
    //   ####
    //   00##
    //       
    Figure([FigureShape([0, 0], [1, 0], [0, 1],  [ 1, 1]),
            FigureShape([0, 0], [1, 0], [0, 1],  [ 1, 1]),
            FigureShape([0, 0], [1, 0], [0, 1],  [ 1, 1]),
            FigureShape([0, 0], [1, 0], [0, 1],  [ 1, 1])]),
    //   ##
    //   ##
    //   00     ##00####
    //   ##    
    Figure([FigureShape([0, 0], [0, 1], [0, 2],  [ 0,-1]),
            FigureShape([0, 0], [1, 0], [2, 0],  [-1, 0]),
            FigureShape([0, 0], [0, 1], [0, 2],  [ 0,-1]),
            FigureShape([0, 0], [1, 0], [2, 0],  [-1, 0])]),
];

enum TetrisAction : int {
    MoveLeft = 10000,
    MoveRight,
    RotateCCW,
    FastDown,
}

class CupWidget : Widget {
    /// cup columns count
    int _cols;
    /// cup rows count
    int _rows;
    int[] _cup;
    /// current figure id
    int _currentFigure;
    /// current figure base point col
    int _currentFigureX;
    /// current figure base point row
    int _currentFigureY;
    /// current figure base point row
    int _currentFigureOrientation;
    /// next figure id
    int _nextFigure;
    /// Level 1..10
    int _level;
    /// Single cell movement duration for current level, in 1/10000000 of seconds
    long _movementDuration;
    /// When true, figure is falling down fast
    bool _fastDownFlag;

    AnimationHelper _animation;

    /// Cup States
    enum CupState : int {
        /// New figure appears
        NewFigure,
        /// Game is paused
        Paused,
        /// Figure is falling
        FallingFigure,
        /// Figure is hanging - pause between falling by one row
        HangingFigure,
        /// destroying complete rows
        DestroyingRows,
        /// Game is over
        GameOver,
    }

    protected CupState _state;

    static const int[10] LEVEL_SPEED = [15000000, 10000000, 7000000, 6000000, 5000000, 4000000, 3500000, 3000000, 2500000, 2000000];

    /// set difficulty level 1..10
    void setLevel(int level) {
        _level = level;
        _movementDuration = LEVEL_SPEED[level - 1];
    }

    void setCupState(CupState state, int animationIntervalPercent = 100, int maxProgress = 10000) {
        _state = state;
        if (animationIntervalPercent)
            _animation.start(_movementDuration * animationIntervalPercent / 100, maxProgress);
        invalidate();
    }

    /// returns true is widget is being animated - need to call animate() and redraw
    override @property bool animating() {
        switch (_state) {
            case CupState.NewFigure:
            case CupState.FallingFigure:
            case CupState.HangingFigure:
            case CupState.DestroyingRows:
                return true;
            default:
                return false;
        }
    }

    /// Turn on / off fast falling down
    bool handleFastDown(bool fast) {
        if (fast == true) {
            // handle turn on fast down
            if (_state == CupState.FallingFigure) {
                _fastDownFlag = true;
                _animation.interval = _movementDuration * 10 / 100; // increase speed
                return true;
            } else if (_state == CupState.HangingFigure) {
                _fastDownFlag = true;
                setCupState(CupState.FallingFigure, 10);
                return true;
            } else {
                return false;
            }
        }
        _fastDownFlag = fast;
        return true;
    }

    bool rotate(int delta) {
        int newOrientation = (_currentFigureOrientation + 4 + delta) & 3;
        if (isPositionFree(_currentFigure, newOrientation, _currentFigureX, _currentFigureY)) {
            if (_state == CupState.FallingFigure && !isPositionFree(_currentFigure, newOrientation, _currentFigureX, _currentFigureY - 1)) {
                if (isPositionFreeBelow())
                    return false;
            }
            _currentFigureOrientation = newOrientation;
            return true;
        }
        return false;
    }

    bool move(int deltaX) {
        int newx = _currentFigureX + deltaX;
        if (isPositionFree(_currentFigure, _currentFigureOrientation, newx, _currentFigureY)) {
            if (_state == CupState.FallingFigure && !isPositionFree(_currentFigure, _currentFigureOrientation, newx, _currentFigureY - 1)) {
                if (isPositionFreeBelow())
                    return false;
            }
            _currentFigureX = newx;
            return true;
        }
        return false;
    }

    protected void onAnimationFinished() {
        switch (_state) {
            case CupState.NewFigure:
                _fastDownFlag = false;
                genNextFigure();
                setCupState(CupState.HangingFigure, 75);
                break;
            case CupState.FallingFigure:
                if (isPositionFreeBelow()) {
                    _currentFigureY--;
                    if (_fastDownFlag)
                        setCupState(CupState.FallingFigure, 10);
                    else
                        setCupState(CupState.HangingFigure, 75);
                } else {
                    // At bottom of cup
                    putFigure(_currentFigure, _currentFigureOrientation, _currentFigureX, _currentFigureY);
                    _fastDownFlag = false;
                    if (!dropNextFigure()) {
                        setCupState(CupState.GameOver);
                    }
                }
                break;
            case CupState.HangingFigure:
                setCupState(CupState.FallingFigure, 25);
                break;
            case CupState.DestroyingRows:
                // TODO
                _fastDownFlag = false;
                break;
            default:
                break;
        }
    }

    /// animates window; interval is time left from previous draw, in hnsecs (1/10000000 of second)
    override void animate(long interval) {
        _animation.animate(interval);
        if (_animation.finished) {
            onAnimationFinished();
        }
    }

    static const int RESERVED_ROWS = 5; // reserved for next figure
    enum : int {
        WALL = -1,
        EMPTY = 0,
        FIGURE1,
        FIGURE2,
        FIGURE3,
        FIGURE4,
        FIGURE5,
        FIGURE6,
    }

    enum : int {
        ORIENTATION0,
        ORIENTATION90,
        ORIENTATION180,
        ORIENTATION270
    }

    static const uint[6] _figureColors = [0xFF0000, 0xA0A000, 0xA000A0, 0x0000FF, 0x800000, 0x408000];

    void genNextFigure() {
        _nextFigure = uniform(FIGURE1, FIGURE6);
    }

    bool dropNextFigure() {
        if (_nextFigure == 0)
            genNextFigure();
        _currentFigure = _nextFigure;
        _currentFigureOrientation = ORIENTATION0;
        _currentFigureX = _cols / 2 - 1;
        _currentFigureY = _rows - 1 - FIGURES[_currentFigure].shapes[_currentFigureOrientation].y0;
        setCupState(CupState.NewFigure, 100, 255);
        return isPositionFree();
    }

    void init(int cols, int rows) {
        _cols = cols;
        _rows = rows;
        _cup = new int[_cols * _rows];
        for (int i = 0; i < _cup.length; i++)
            _cup[i] = EMPTY;
    }

    protected int cell(int col, int row) {
        if (col < 0 || row < 0 || col >= _cols || row >= _rows)
            return WALL;
        return _cup[row * _cols + col];
    }

    protected void setCell(int col, int row, int value) {
        _cup[row * _cols + col] = value;
        invalidate();
    }

    protected Rect cellRect(Rect rc, int col, int row) {
        int dx = rc.width / _cols;
        int dy = rc.height / (_rows + RESERVED_ROWS);
        int dd = dx;
        if (dd > dy)
            dd = dy;
        int x0 = rc.left + (rc.width - dd * _cols) / 2 + dd * col;
        int y0 = rc.bottom - (rc.height - dd * (_rows + RESERVED_ROWS)) / 2 - dd * row - dd;
        return Rect(x0, y0, x0 + dd, y0 + dd);
    }

    protected void drawCell(DrawBuf buf, Rect cellRc, uint color) {
        cellRc.right--;
        cellRc.bottom--;
        int w = cellRc.width / 6;
        buf.drawFrame(cellRc, color, Rect(w,w,w,w));
        cellRc.shrink(w, w);
        color = addAlpha(color, 0xC0);
        buf.fillRect(cellRc, color);
    }

    protected void drawFigure(DrawBuf buf, Rect rc, int figureIndex, int orientation, int x, int y, int dy, uint alpha = 0) {
        uint color = addAlpha(_figureColors[figureIndex - 1], alpha);
        FigureShape shape = FIGURES[figureIndex - 1].shapes[orientation];
        for (int i = 0; i < 4; i++) {
            Rect cellRc = cellRect(rc, x + shape.cells[i].dx, y + shape.cells[i].dy);
            cellRc.top += dy;
            cellRc.bottom += dy;
            drawCell(buf, cellRc, color);
        }
    }

    protected bool isPositionFree() {
        return isPositionFree(_currentFigure, _currentFigureOrientation, _currentFigureX, _currentFigureY);
    }

    protected bool isPositionFreeBelow() {
        return isPositionFree(_currentFigure, _currentFigureOrientation, _currentFigureX, _currentFigureY - 1);
    }

    protected bool isPositionFree(int figureIndex, int orientation, int x, int y) {
        FigureShape shape = FIGURES[figureIndex - 1].shapes[orientation];
        for (int i = 0; i < 4; i++) {
            int value = cell(x + shape.cells[i].dx, y + shape.cells[i].dy);
            if (value != 0) // occupied
                return false;
        }
        return true;
    }

    protected void putFigure(int figureIndex, int orientation, int x, int y) {
        FigureShape shape = FIGURES[figureIndex - 1].shapes[orientation];
        for (int i = 0; i < 4; i++) {
            setCell(x + shape.cells[i].dx, y + shape.cells[i].dy, figureIndex);
        }
    }

    /// Handle keys.
    override bool onKeyEvent(KeyEvent event) {
        if (event.action == KeyAction.KeyDown && _state == CupState.GameOver) {
            newGame();
            return true;
        }
        if (event.keyCode == KeyCode.DOWN) {
            if (event.action == KeyAction.KeyDown) {
                handleFastDown(true);
            } else if (event.action == KeyAction.KeyUp) {
                handleFastDown(false);
            }
            return true;
        }
        handleFastDown(false);
        return super.onKeyEvent(event);
    }

    /// Draw widget at its position to buffer
    override void onDraw(DrawBuf buf) {
        super.onDraw(buf);
        Rect rc = _pos;
        applyMargins(rc);
		auto saver = ClipRectSaver(buf, rc, alpha);
	    applyPadding(rc);

        Rect topLeft = cellRect(rc, 0, _rows - 1);
        Rect bottomRight = cellRect(rc, _cols - 1, 0);
        Rect cupRc = Rect(topLeft.left, topLeft.top, bottomRight.right, bottomRight.bottom);

        int fw = 7;
        int dw = 0;
        uint fcl = 0xA0606090;
        buf.fillRect(cupRc, 0xC0A0C0B0);
        buf.fillRect(Rect(cupRc.left - dw - fw, cupRc.top, cupRc.left - dw,       cupRc.bottom + dw), fcl);
        buf.fillRect(Rect(cupRc.right + dw,     cupRc.top, cupRc.right + dw + fw, cupRc.bottom + dw), fcl);
        buf.fillRect(Rect(cupRc.left - dw - fw, cupRc.bottom + dw, cupRc.right + dw + fw, cupRc.bottom + dw + fw), fcl);

        for (int row = 0; row < _rows; row++) {
            for (int col = 0; col < _cols; col++) {

                int value = cell(col, row);
                Rect cellRc = cellRect(rc, col, row);

                Point middle = cellRc.middle;
                buf.fillRect(Rect(middle.x - 1, middle.y - 1, middle.x + 1, middle.y + 1), 0x80404040);

                if (value != EMPTY) {
                    uint cl = _figureColors[value - 1];
                    drawCell(buf, cellRc, cl);
                }
            }
        }

        // draw current figure falling
        if (_state == CupState.FallingFigure || _state == CupState.HangingFigure) {
            int dy = 0;
            if (_state == CupState.FallingFigure && isPositionFreeBelow()) {
                dy = _animation.getProgress(topLeft.height);
            }
            drawFigure(buf, rc, _currentFigure, _currentFigureOrientation, _currentFigureX, _currentFigureY, dy, 0);
        }


        if (_nextFigure != 0) {
            auto shape = FIGURES[_nextFigure - 1].shapes[0];
            uint nextFigureAlpha = 0;
            if (_state == CupState.NewFigure) {
                nextFigureAlpha = _animation.progress;
                drawFigure(buf, rc, _currentFigure, _currentFigureOrientation, _currentFigureX, _currentFigureY, 0, 255 - nextFigureAlpha);
            }
            drawFigure(buf, rc, _nextFigure, ORIENTATION0, _cols / 2 - 1, _rows - shape.extent + 1, 0, blendAlpha(0xA0, nextFigureAlpha));
        }

    }
    /// Measure widget according to desired width and height constraints. (Step 1 of two phase layout).
    override void measure(int parentWidth, int parentHeight) { 
        /// fixed size 350 x 550
        measuredContent(parentWidth, parentHeight, 350, 550);
    }

	/// override to handle specific actions
	override bool handleAction(const Action a) {
        switch (a.id) {
            case TetrisAction.MoveLeft:
                move(-1);
                return true;
            case TetrisAction.MoveRight:
                move(1);
                return true;
            case TetrisAction.RotateCCW:
                rotate(1);
                return true;
            case TetrisAction.FastDown:
                handleFastDown(true);
                return true;
            default:
                if (parent) // by default, pass to parent widget
                    return parent.handleAction(a);
                return false;
        }
	}

    void newGame() {
        setLevel(1);
        init(_cols, _rows);
        dropNextFigure();
    }

    this() {
        super("CUP");
        layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT).layoutWeight(3);
        setState(State.Default);
        backgroundColor = 0xC0808080;
        padding(Rect(20, 20, 20, 20));
        _cols = 11;
        _rows = 15;
        newGame();

        focusable = true;

		acceleratorMap.add( [
			new Action(TetrisAction.MoveLeft,  KeyCode.LEFT, 0),
			new Action(TetrisAction.MoveRight, KeyCode.RIGHT, 0),
			new Action(TetrisAction.RotateCCW, KeyCode.UP, 0),
			new Action(TetrisAction.FastDown,  KeyCode.SPACE, 0),
		]);

    }
}

class StatusWidget : VerticalLayout {
    TextWidget _score;
    TextWidget _lblNext;
    this() {
        super("CUP_STATUS");
        _score = new TextWidget("SCORE", "Score: 0"d);
        _lblNext = new TextWidget("NEXT", "Next:"d);
        backgroundColor = 0xC080FF80;
        addChild(_score);
        addChild(_lblNext);
        layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT).layoutWeight(2);
        padding(Rect(20, 20, 20, 20));
    }
    /// Measure widget according to desired width and height constraints. (Step 1 of two phase layout).
    override void measure(int parentWidth, int parentHeight) { 
        super.measure(parentWidth, parentHeight);
        /// fixed size 350 x 550
        measuredContent(parentWidth, parentHeight, 150, 550);
    }
}

class CupPage : HorizontalLayout {
    CupWidget _cup;
    StatusWidget _status;
    this() {
        super("CUP_PAGE");
        layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
        _cup = new CupWidget();
        _status = new StatusWidget();
        addChild(_cup);
        addChild(_status);
    }
    /// Measure widget according to desired width and height constraints. (Step 1 of two phase layout).
    override void measure(int parentWidth, int parentHeight) { 
        super.measure(parentWidth, parentHeight);
        /// fixed size 350 x 550
        measuredContent(parentWidth, parentHeight, 500, 550);
    }
}

//FrameLayout
class GameWidget : HorizontalLayout {

    CupPage _cupPage;
    this() {
        super("GAME");
        _cupPage = new CupPage();
        addChild(_cupPage);
        //showChild(_cupPage.id, Visibility.Invisible, true);
		backgroundImageId = "tx_fabric.tiled";
    }
    /// Measure widget according to desired width and height constraints. (Step 1 of two phase layout).
    override void measure(int parentWidth, int parentHeight) {
        super.measure(parentWidth, parentHeight);
        measuredContent(parentWidth, parentHeight, 500, 550);
    }
}

enum : int {
    ACTION_FILE_OPEN = 5500,
    ACTION_FILE_SAVE,
    ACTION_FILE_CLOSE,
    ACTION_FILE_EXIT,
}

/// entry point for dlangui based application
extern (C) int UIAppMain(string[] args) {

    auto power2 = delegate(int X) { return X * X; };

    // resource directory search paths
    string[] resourceDirs = [
        	appendPath(exePath, "../../../res/"),   // for Visual D and DUB builds
	        appendPath(exePath, "../../../res/mdpi/"),   // for Visual D and DUB builds
	        appendPath(exePath, "../../../../res/"),// for Mono-D builds
	        appendPath(exePath, "../../../../res/mdpi/"),// for Mono-D builds
		appendPath(exePath, "res/"), // when res dir is located at the same directory as executable
		appendPath(exePath, "../res/"), // when res dir is located at project directory
		appendPath(exePath, "../../res/"), // when res dir is located at the same directory as executable
		appendPath(exePath, "res/mdpi/"), // when res dir is located at the same directory as executable
		appendPath(exePath, "../res/mdpi/"), // when res dir is located at project directory
		appendPath(exePath, "../../res/mdpi/") // when res dir is located at the same directory as executable
	];

    // setup resource directories - will use only existing directories
	Platform.instance.resourceDirs = resourceDirs;
    // select translation file - for english language
	Platform.instance.uiLanguage = "en";
	// load theme from file "theme_default.xml"
	Platform.instance.uiTheme = "theme_default";

    //drawableCache.get("tx_fabric.tiled");

    // create window
    Window window = Platform.instance.createWindow("DLangUI: Tetris game example", null, WindowFlag.Modal);

    GameWidget game = new GameWidget();

    window.mainWidget = game;

    window.windowIcon = drawableCache.getImage("dtetris-logo1");

    window.show();

    // run message loop
    return Platform.instance.enterMessageLoop();
}
