/*
    NanoCorona compact top command bar.
    It is a normal dockable CUI dialog bar, so it does not modify a user's CUIX layout.
*/

global NanoCoronaToolbar
global NanoCoronaToolbarDir
global NanoCoronaPanelVisible
global NanoCoronaTogglePanel
global NanoCoronaToolbarSync

try (cui.UnRegisterDialogBar NanoCoronaToolbar) catch()
try (destroyDialog NanoCoronaToolbar) catch()

NanoCoronaToolbarDir = getFilenamePath (getSourceFileName())

fn NanoCoronaToolbarEnsurePanelApi =
(
    local panelPath = ""

    if NanoCoronaTogglePanel == undefined then
    (
        panelPath = NanoCoronaToolbarDir + "NanoCorona_VFB_Prototype.ms"
        if not doesFileExist panelPath then
        (
            try (panelPath = (getDir #userScripts) + "\\NanoCorona\\NanoCorona_VFB_Prototype.ms") catch()
        )
        if doesFileExist panelPath do try (fileIn panelPath) catch()
    )

    NanoCoronaTogglePanel != undefined
)

fn NanoCoronaToolbarSync =
(
    try
    (
        if NanoCoronaPanelVisible then
        (
            NanoCoronaToolbar.toggleButton.caption = "HIDE NANOCORONA"
            NanoCoronaToolbar.statusLabel.text = "Panel open"
        )
        else
        (
            NanoCoronaToolbar.toggleButton.caption = "OPEN NANOCORONA"
            NanoCoronaToolbar.statusLabel.text = "AI controls ready"
        )
    ) catch()
)

rollout NanoCoronaToolbar "NanoCorona" width:390 height:34
(
    label brandLabel "NANOCORONA" width:116 align:#left
    button toggleButton "OPEN NANOCORONA" width:166 height:26 across:2 tooltip:"Open or hide the NanoCorona AI panel"
    label statusLabel "AI controls ready" width:100 align:#right

    on toggleButton pressed do
    (
        if NanoCoronaToolbarEnsurePanelApi() then
        (
            NanoCoronaTogglePanel()
            NanoCoronaToolbarSync()
        )
        else
        (
            messageBox "NanoCorona panel script was not found. Reinstall NanoCorona." title:"NanoCorona"
        )
    )

    on NanoCoronaToolbar open do NanoCoronaToolbarSync()
)

createDialog NanoCoronaToolbar 390 34 style:#(#style_titlebar, #style_sysmenu)
cui.RegisterDialogBar NanoCoronaToolbar style:#(#cui_dock_top, #cui_floatable, #cui_handles)
cui.DockDialogBar NanoCoronaToolbar #cui_dock_top
