// Written in the D programming language.

/**
This module contains FileDialog implementation.

Can show dialog for open / save.


Synopsis:

----
import dlangui.dialogs.filedlg;

UIString caption = "Open File"d;
auto dlg = new FileDialog(caption, window, FileDialogFlag.Open);
dlg.show();

----

Copyright: Vadim Lopatin, 2014
License:   Boost License 1.0
Authors:   Vadim Lopatin, coolreader.org@gmail.com
*/
module dlangui.dialogs.filedlg;

import dlangui.core.events;
import dlangui.core.i18n;
import dlangui.core.stdaction;
import dlangui.core.files;
import dlangui.widgets.controls;
import dlangui.widgets.lists;
import dlangui.widgets.popup;
import dlangui.widgets.layouts;
import dlangui.widgets.grid;
import dlangui.widgets.editors;
import dlangui.platforms.common.platform;
import dlangui.dialogs.dialog;

private import std.file;
private import std.path;
private import std.utf;
private import std.conv : to;


/// flags for file dialog options
enum FileDialogFlag : uint {
    /// file must exist (use this for open dialog)
    FileMustExist = 0x100,
    /// ask before saving to existing
    ConfirmOverwrite = 0x200,
    /// flags for Open dialog
    Open = FileMustExist,
    /// flags for Save dialog
    Save = ConfirmOverwrite,
}

/// File open / save dialog
class FileDialog : Dialog, CustomGridCellAdapter {
	protected EditLine _edPath;
	protected EditLine _edFilename;
	protected StringGridWidget _fileList;
	//protected StringGridWidget places;
	protected VerticalLayout leftPanel;
	protected VerticalLayout rightPanel;
    protected Action _action;

    protected RootEntry[] _roots;
    protected string _path;
    protected string _filename;
    protected DirEntry[] _entries;
    protected bool _isRoot;

	this(UIString caption, Window parent, Action action = null, uint fileDialogFlags = DialogFlag.Modal | DialogFlag.Resizable | FileDialogFlag.FileMustExist) {
        super(caption, parent, fileDialogFlags);
        _action = action;
    }

    /// Set widget rectangle to specified value and layout widget contents. (Step 2 of two phase layout).
    override void layout(Rect rc) {
        super.layout(rc);
        _fileList.autoFitColumnWidths();
        _fileList.fillColumnWidth(1);
    }

    protected bool openDirectory(string dir) {
        dir = buildNormalizedPath(dir);
        Log.d("FileDialog.openDirectory(", dir, ")");
        _fileList.rows = 0;
        string[] filters;
        if (!listDirectory(dir, true, true, false, filters, _entries))
            return false;
        _path = dir;
        _isRoot = isRoot(dir);
        _edPath.text = toUTF32(_path);
        _fileList.rows = cast(int)_entries.length;
        for (int i = 0; i < _entries.length; i++) {
            string fname = baseName(_entries[i].name);
            string sz;
            string date;
            bool d = _entries[i].isDir;
            _fileList.setCellText(1, i, toUTF32(fname));
            if (d) {
                _fileList.setCellText(0, i, "folder");
            } else {
                _fileList.setCellText(0, i, "text-plain"d);
                sz = to!string(_entries[i].size);
                date = "2014-01-01 00:00:00";
            }
            _fileList.setCellText(2, i, toUTF32(sz));
            _fileList.setCellText(3, i, toUTF32(date));
        }
        _fileList.autoFitColumnWidths();
        _fileList.fillColumnWidth(1);
        return true;
    }

    /// return true for custom drawn cell
    override bool isCustomCell(int col, int row) {
        if (col == 0 && row >= 0)
            return true;
        return false;
    }

    protected DrawableRef rowIcon(int row) {
        string iconId = toUTF8(_fileList.cellText(0, row));
        DrawableRef res;
        if (iconId.length)
            res = drawableCache.get(iconId);
        return res;
    }

    /// return cell size
    override Point measureCell(int col, int row) {
        DrawableRef icon = rowIcon(row);
        if (icon.isNull)
            return Point(0, 0);
        return Point(icon.width + 2, icon.height + 2);
    }

	/// draw data cell content
	override void drawCell(DrawBuf buf, Rect rc, int col, int row) {
        DrawableRef img = rowIcon(row);
        if (!img.isNull) {
            Point sz;
            sz.x = img.width;
            sz.y = img.height;
            applyAlign(rc, sz, Align.HCenter, Align.VCenter);
            uint st = state;
            img.drawTo(buf, rc, st);
        }
    }

    protected Widget createRootsList() {
        ListWidget res = new ListWidget("ROOTS_LIST");
        WidgetListAdapter adapter = new WidgetListAdapter();
        foreach(ref RootEntry root; _roots) {
            ImageTextButton btn = new ImageTextButton(null, root.icon, root.label);
            btn.orientation = Orientation.Vertical;
            btn.styleId = "TRANSPARENT_BUTTON_BACKGROUND";
            btn.focusable = false;
            adapter.widgets.add(btn);
        }
        res.ownAdapter = adapter;
        res.layoutWidth = WRAP_CONTENT;
        res.layoutHeight = FILL_PARENT;
        res.onItemClickListener = delegate(Widget source, int itemIndex) {
            openDirectory(_roots[itemIndex].path);
            return true;
        };
        return res;
    }

    protected void onItemActivated(int index) {
        DirEntry e = _entries[index];
        if (e.isDir) {
            openDirectory(e.name);
        } else if (e.isFile) {
            string fname = e.name;
            Action result = ACTION_OPEN.clone();
            result.stringParam = fname;
            close(result);
        }

    }

	/// override to implement creation of dialog controls
	override void init() {
        _roots = getRootPaths;

		layoutWidth(FILL_PARENT);
		layoutWidth(FILL_PARENT);
        minWidth = 600;
        minHeight = 400;

		LinearLayout content = new HorizontalLayout("dlgcontent");

		content.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT).minWidth(400).minHeight(300);

		leftPanel = new VerticalLayout("places");
        leftPanel.addChild(createRootsList());
		leftPanel.layoutHeight(FILL_PARENT).minWidth(40);

		rightPanel = new VerticalLayout("main");
		rightPanel.layoutHeight(FILL_PARENT).layoutWidth(FILL_PARENT);
		rightPanel.addChild(new TextWidget(null, "Path:"d));

		content.addChild(leftPanel);
		content.addChild(rightPanel);

		_edPath = new EditLine("path");
		_edPath.layoutWidth(FILL_PARENT);
        _edPath.layoutWeight = 0;

		_edFilename = new EditLine("path");
		_edFilename.layoutWidth(FILL_PARENT);
        _edFilename.layoutWeight = 0;

		rightPanel.addChild(_edPath);
		_fileList = new StringGridWidget("files");
		_fileList.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
		_fileList.resize(4, 3);
		_fileList.setColTitle(0, " "d);
		_fileList.setColTitle(1, "Name"d);
		_fileList.setColTitle(2, "Size"d);
		_fileList.setColTitle(3, "Modified"d);
		_fileList.showRowHeaders = false;
		_fileList.rowSelect = true;
		rightPanel.addChild(_fileList);
		rightPanel.addChild(_edFilename);


		addChild(content);
		addChild(createButtonsPanel([ACTION_OPEN, ACTION_CANCEL], 0, 0));

        _fileList.customCellAdapter = this;
        _fileList.onCellActivated = delegate(GridWidgetBase source, int col, int row) {
            onItemActivated(row);
        };

        openDirectory(currentDir);
        _fileList.layoutHeight = FILL_PARENT;

        _fileList.setFocus();
	}
}
