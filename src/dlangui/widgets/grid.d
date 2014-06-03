module dlangui.widgets.grid;

import dlangui.widgets.widget;
import dlangui.widgets.controls;
import std.conv;

/**
 * Data provider for GridWidget.
 */
interface GridAdapter {
	/// number of columns
	@property int cols();
	/// number of rows
	@property int rows();
	/// returns widget to draw cell at (col, row)
	Widget cellWidget(int col, int row);
	/// returns row header widget, null if no header
	Widget rowHeader(int row);
	/// returns column header widget, null if no header
	Widget colHeader(int col);
}

/**
 */
class StringGridAdapter : GridAdapter {
	protected int _cols;
	protected int _rows;
	protected dstring[][] _data;
	protected dstring[] _rowTitles;
	protected dstring[] _colTitles;
	/// number of columns
	@property int cols() { return _cols; }
	/// number of columns
	@property void cols(int v) { resize(v, _rows); }
	/// number of rows
	@property int rows() { return _rows; }
	/// number of columns
	@property void rows(int v) { resize(_cols, v); }

	/// returns row header title
	dstring rowTitle(int row) {
		return _rowTitles[row];
	}
	/// set row header title
	StringGridAdapter setRowTitle(int row, dstring title) {
		_rowTitles[row] = title;
		return this;
	}
	/// returns row header title
	dstring colTitle(int col) {
		return _colTitles[col];
	}
	/// set col header title
	StringGridAdapter setColTitle(int col, dstring title) {
		_colTitles[col] = title;
		return this;
	}
	/// get cell text
	dstring cellText(int col, int row) {
		return _data[row][col];
	}
	/// set cell text
	StringGridAdapter setCellText(int col, int row, dstring text) {
		_data[row][col] = text;
		return this;
	}
	/// set new size
	void resize(int cols, int rows) {
		if (cols == _cols && rows == _rows)
			return;
		_cols = cols;
		_rows = rows;
		_data.length = _rows;
		for (int y = 0; y < _rows; y++)
			_data[y].length = _cols;
		_colTitles.length = _cols;
		_rowTitles.length = _rows;
	}
	/// returns widget to draw cell at (col, row)
	Widget cellWidget(int col, int row) { return null; }
	/// returns row header widget, null if no header
	Widget rowHeader(int row) { return null; }
	/// returns column header widget, null if no header
	Widget colHeader(int col) { return null; }
}

class GridWidgetBase : WidgetGroup {
	@property abstract int cols();
	@property abstract GridWidgetBase cols(int c);
	@property abstract int rows();
	@property abstract GridWidgetBase rows(int r);
	/// flag to enable column headers
	@property abstract bool showColHeaders();
	@property abstract GridWidgetBase showColHeaders(bool show);
	/// flag to enable row headers
	@property abstract bool showRowHeaders();
	@property abstract GridWidgetBase showRowHeaders(bool show);
	this(string ID = null) {
		super(ID);
	}
}

/**
 * Grid view with string data shown. All rows are of the same height.
 */
class StringGridWidget : GridWidgetBase {
	protected ScrollBar _vscrollbar;
	protected ScrollBar _hscrollbar;
	protected int _cols;
	protected int _rows;
	protected dstring[][] _data;
	protected dstring[] _rowTitles;
	protected dstring[] _colTitles;
	protected int[] _colWidths;
	protected int[] _rowHeights;
    /// number of header rows (e.g. like col name A, B, C... in excel; 0 for no header row)
    protected int _headerRows;
    /// number of header columns (e.g. like row number in excel; 0 for no header column)
    protected int _headerCols;
    /// number of fixed (non-scrollable) columns
    protected int _fixedCols;
    /// number of fixed (non-scrollable) rows
    protected int _fixedRows;
    /// column scroll offset, relative to last fixed col; 0 = not scrolled
    protected int _scrollCol; 
    /// row scroll offset, relative to last fixed row; 0 = not scrolled
    protected int _scrollRow;
	this(string ID = null) {
		super(ID);
		_headerCols = 1;
		_headerRows = 1;
		_vscrollbar = new ScrollBar("vscrollbar", Orientation.Vertical);
		_hscrollbar = new ScrollBar("hscrollbar", Orientation.Horizontal);
		addChild(_vscrollbar);
		addChild(_hscrollbar);
		styleId = "EDIT_BOX";
        resize(20, 30);
	}
	@property override int cols() {
		return _cols;
	}
	@property override GridWidgetBase cols(int c) {
		resize(c, _rows);
		return this;
	}
	@property override int rows() {
		return _rows;
	}
	@property override GridWidgetBase rows(int r) {
		resize(_cols, r);
		return this;
	}
	/// flag to enable column headers
	@property override bool showColHeaders() {
		return _headerRows > 0;
	}
	@property override GridWidgetBase showColHeaders(bool show) {
		_headerRows = show ? 1 : 0;
		return this;
	}
	/// flag to enable row headers
	@property override bool showRowHeaders() {
		return _headerCols > 0;
	}
	@property override GridWidgetBase showRowHeaders(bool show) {
		_headerCols = show ? 1 : 0;
		return this;
	}
	/// get cell text
	dstring cellText(int col, int row) {
		return _data[row][col];
	}
	/// set cell text
	GridWidgetBase setCellText(int col, int row, dstring text) {
		_data[row][col] = text;
		return this;
	}

    /// zero based index generation of column header - like in Excel - for testing
    dstring genColHeader(int col) {
        dstring res;
        int n1 = col / 26;
        int n2 = col % 26;
        if (n1)
            res ~= n1 + 'A';
        res ~= n2 + 'A';
        return res;
    }

	/// set new size
	void resize(int cols, int rows) {
		if (cols == _cols && rows == _rows)
			return;
		_data.length = rows;
		for (int y = 0; y < rows; y++)
			_data[y].length = cols;
		_colTitles.length = cols;
        for (int i = _cols; i < cols; i++)
            _colTitles[i] = i > 0 ? ("col "d ~ to!dstring(i)) : ""d;
		_rowTitles.length = rows;
		_colWidths.length = cols;
        for (int i = _cols; i < cols; i++) {
            if (i >= _headerCols)
                _data[0][i] = genColHeader(i - _headerCols);
            _colWidths[i] = i == 0 ? 20 : 80;
        }
		_rowHeights.length = rows;
        int fontHeight = font.height;
        for (int i = _rows; i < rows; i++) {
            if (i >= _headerRows)
                _data[i][0] = to!dstring(i - _headerRows + 1);
            _rowHeights[i] = fontHeight + 2;
        }
		_cols = cols;
		_rows = rows;
	}

    /// returns column width (index includes col/row headers, if any); returns 0 for columns hidden by scroll at the left
    int colWidth(int x) {
        if (x >= _headerCols + _fixedCols && x < _headerCols + _fixedCols + _scrollCol)
            return 0;
        return _colWidths[x];
    }

    /// returns row height (index includes col/row headers, if any); returns 0 for riws hidden by scroll at the top
    int rowHeight(int y) {
        if (y >= _headerRows + _fixedRows && y < _headerRows + _fixedRows + _scrollRow)
            return 0;
        return _rowHeights[y];
    }

    /// returns cell rectangle relative to client area; row 0 is col headers row; col 0 is row headers column
    Rect cellRect(int x, int y) {
        Rect rc;
        int xx = 0;
        for (int i = 0; i <= x; i++) {
            if (i == x)
                rc.left = xx;
            xx += colWidth(i);
            if (i == x) {
                rc.right = xx;
                break;
            }
        }
        int yy = 0;
        for (int i = 0; i <= y; i++) {
            if (i == y)
                rc.top = yy;
            yy += rowHeight(i);
            if (i == x) {
                rc.bottom = yy;
                break;
            }
        }
        return rc;
    }
	/// returns row header title
	dstring rowTitle(int row) {
		return _rowTitles[row];
	}
	/// set row header title
	GridWidgetBase setRowTitle(int row, dstring title) {
		_rowTitles[row] = title;
		return this;
	}
	/// returns row header title
	dstring colTitle(int col) {
		return _colTitles[col];
	}
	/// set col header title
	GridWidgetBase setColTitle(int col, dstring title) {
		_colTitles[col] = title;
		return this;
	}
	/// draw column header
	void drawColHeader(DrawBuf buf, Rect rc, int index) {
        //FontRef fnt = font;
        //buf.fillRect(rc, 0xE0E0E0);
        //buf.drawFrame(rc, 0x808080, Rect(1,1,1,1));
        //fnt.drawText(buf, rc.left, rc.top, "col"d, 0x000000);
	}
	/// draw row header
	void drawRowHeader(DrawBuf buf, Rect rc, int index) {
        //FontRef fnt = font;
        //buf.fillRect(rc, 0xE0E0E0);
        //buf.drawFrame(rc, 0x808080, Rect(1,1,1,1));
        //fnt.drawText(buf, rc.left, rc.top, "row"d, 0x000000);
	}

	/// Measure widget according to desired width and height constraints. (Step 1 of two phase layout).
	override void measure(int parentWidth, int parentHeight) { 
		Rect m = margins;
		Rect p = padding;
		// calc size constraints for children
		int pwidth = parentWidth;
		int pheight = parentHeight;
		if (parentWidth != SIZE_UNSPECIFIED)
			pwidth -= m.left + m.right + p.left + p.right;
		if (parentHeight != SIZE_UNSPECIFIED)
			pheight -= m.top + m.bottom + p.top + p.bottom;
		_hscrollbar.measure(pwidth, pheight);
		_vscrollbar.measure(pwidth, pheight);
		measuredContent(parentWidth, parentHeight, 100, 100);
	}

	protected Rect _clientRect;

	/// Set widget rectangle to specified value and layout widget contents. (Step 2 of two phase layout).
	override void layout(Rect rc) {
		if (visibility == Visibility.Gone) {
			return;
		}
		_pos = rc;
		_needLayout = false;
		applyMargins(rc);
		applyPadding(rc);
		// scrollbars
		Rect vsbrc = rc;
		vsbrc.left = vsbrc.right - _vscrollbar.measuredWidth;
		vsbrc.bottom = vsbrc.bottom - _hscrollbar.measuredHeight;
		Rect hsbrc = rc;
		hsbrc.right = hsbrc.right - _vscrollbar.measuredWidth;
		hsbrc.top = hsbrc.bottom - _hscrollbar.measuredHeight;
		_vscrollbar.layout(vsbrc);
		_hscrollbar.layout(hsbrc);
		// client area
		_clientRect = rc;
		_clientRect.right = vsbrc.left;
		_clientRect.bottom = hsbrc.top;
	}

	/// draw cell content
	void drawCell(DrawBuf buf, Rect rc, int col, int row) {
        rc.shrink(1, 1);
		FontRef fnt = font;
        dstring txt = cellText(col, row);
        Point sz = fnt.textSize(txt);
        Align ha = Align.Left;
        if (col < _headerCols)
            ha = Align.Right;
        if (row < _headerRows)
            ha = Align.HCenter;
        applyAlign(rc, sz, ha, Align.VCenter);
		fnt.drawText(buf, rc.left + 1, rc.top + 1, txt, 0x000000);
	}

	/// draw cell background
	void drawCellBackground(DrawBuf buf, Rect rc, int col, int row) {
        Rect vborder = rc;
        Rect hborder = rc;
        vborder.left = vborder.right - 1;
        hborder.top = hborder.bottom - 1;
        hborder.right--;
        if (col < _headerCols || row < _headerRows) {
            // draw header cell background
            buf.fillRect(rc, 0x80808080);
            buf.fillRect(vborder, 0x80FFFFFF);
            buf.fillRect(hborder, 0x80FFFFFF);
        } else {
            // normal cell background
            buf.fillRect(vborder, 0x80C0C0C0);
            buf.fillRect(hborder, 0x80C0C0C0);
        }
	}

	void drawClient(DrawBuf buf) {
		auto saver = ClipRectSaver(buf, _clientRect, 0);
		//buf.fillRect(_clientRect, 0x80A08080);
        Rect rc;
        for (int phase = 0; phase < 2; phase++) {
            int yy = 0;
            for (int y = 0; y < _rows; y++) {
                int rh = rowHeight(y);
                rc.top = yy;
                rc.bottom = yy + rh;
                if (rh == 0)
                    continue;
                if (yy > _clientRect.height)
                    break;
                yy += rh;
                int xx = 0;
                for (int x = 0; x < _cols; x++) {
                    int cw = colWidth(x);
                    rc.left = xx;
                    rc.right = xx + cw;
                    if (cw == 0)
                        continue;
                    if (xx > _clientRect.width)
                        break;
                    xx += cw;
                    // draw cell
                    Rect cellRect = rc;
                    cellRect.moveBy(_clientRect.left, _clientRect.top);
                    auto cellSaver = ClipRectSaver(buf, cellRect, 0);
                    if (phase == 0)
                        drawCellBackground(buf, cellRect, x, y);
                    else
                        drawCell(buf, cellRect, x, y);
                }
            }
        }
	}
	/// Draw widget at its position to buffer
	override void onDraw(DrawBuf buf) {
		if (visibility != Visibility.Visible)
			return;
		Rect rc = _pos;
		applyMargins(rc);
		auto saver = ClipRectSaver(buf, rc, alpha);
		DrawableRef bg = backgroundDrawable;
		if (!bg.isNull) {
			bg.drawTo(buf, rc, state);
		}
		applyPadding(rc);
		_hscrollbar.onDraw(buf);
		_vscrollbar.onDraw(buf);
		drawClient(buf);
		_needDraw = false;
	}
}

/**
 * Multicolumn multirow view.
 */
class GridWidget : WidgetGroup {
	protected GridAdapter _adapter;
	/// when true, widget owns adapter and must destroy it itself.
	protected bool _ownAdapter;
	protected int _cols;
	protected int _rows;
	/// returns current grid adapter
	@property GridAdapter adapter() { return _adapter; }
	/// sets shared adapter (will not be destroyed on widget destroy)
	@property GridWidget adapter(GridAdapter a) {
		if (_ownAdapter && _adapter)
			destroy(_adapter);
		_ownAdapter = false;
		_adapter = a;
		return this;
	}
	/// sets own adapter (will be destroyed on widget destroy)
	@property GridWidget ownAdapter(GridAdapter a) {
		if (_ownAdapter && _adapter)
			destroy(_adapter);
		_adapter = a;
		return this;
	}
	/// destroy own adapter
	~this() {
		if (_ownAdapter && _adapter)
			destroy(_adapter);
	}
}

