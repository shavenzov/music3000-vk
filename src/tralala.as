import classes.api.MainAPI;
import classes.api.events.ServerUpdateEvent;

import components.controls.HTMLToolTip;
import components.managers.PopUpManager;
import components.managers.events.PopUpEvent;

import flash.events.KeyboardEvent;
import flash.events.UncaughtErrorEvent;
import flash.external.ExternalInterface;
import flash.ui.Keyboard;

import flashx.textLayout.elements.Configuration;
import flashx.textLayout.elements.TextFlow;
import flashx.textLayout.formats.TextDecoration;
import flashx.textLayout.formats.TextLayoutFormat;

import mx.core.FlexGlobals;
import mx.effects.Fade;
import mx.managers.CursorManager;
import mx.managers.CursorManagerPriority;
import mx.managers.FocusManager;
import mx.managers.ToolTipManager;
import mx.managers.history.History;
import mx.styles.CSSStyleDeclaration;

private function init() : void
{
	ToolTipManager.showEffect = new Fade();
	ToolTipManager.hideEffect = new Fade();
	
	defaultStyling();
	
	PopUpManager.dispatcher.addEventListener( PopUpEvent.OPEN, onPopUp );
	PopUpManager.dispatcher.addEventListener( PopUpEvent.CLOSE, onPopUp );
	
	MainAPI.impl.addListener( ServerUpdateEvent.START_UPDATE, onStartUpdate, this );
	MainAPI.impl.addListener( ServerUpdateEvent.END_UPDATE, onEndUpdate, this );
	
	var css1 : CSSStyleDeclaration = styleManager.getStyleDeclaration( '.toolTip' );
	
	if ( css1 )
	{
		var css2 : CSSStyleDeclaration = new CSSStyleDeclaration( 'mx.controls.ToolTip' );
		css2.defaultFactory = css1.factory;
		styleManager.setStyleDeclaration( 'mx.controls.ToolTip', css2, false );
	}
}

private var serverUpdateDialog : ServerUpdateDialog;

private function onStartUpdate( e : ServerUpdateEvent ) : void
{
	if ( ! serverUpdateDialog )
	{
		serverUpdateDialog = new ServerUpdateDialog();
		serverUpdateDialog.end = e.end;
		serverUpdateDialog.reason = e.reason;
		PopUpManager.addPopUp( serverUpdateDialog, this, true );
		PopUpManager.centerPopUp( serverUpdateDialog );
	}
}

private function onEndUpdate( e : ServerUpdateEvent ) : void
{
	ExternalInterface.call( 'window.location.reload' );
	serverUpdateDialog.currentState = 'updated';
}

private function onPreinitialize() : void
{
	defaultStyling();
}

private function defaultStyling() : void
{
	var cfg:Configuration = TextFlow.defaultConfiguration;
	
	var normalTLF:TextLayoutFormat = new TextLayoutFormat(cfg.defaultLinkNormalFormat);
	normalTLF.color = 0xEF8200;
	
	var hoverTLF:TextLayoutFormat = new TextLayoutFormat(cfg.defaultLinkHoverFormat);
	hoverTLF.color = 0xEF8200;
	hoverTLF.textDecoration = TextDecoration.UNDERLINE;
	
	var activeTLF:TextLayoutFormat = new TextLayoutFormat(cfg.defaultLinkActiveFormat);
	activeTLF.color = 0xEF8200;
	activeTLF.textDecoration = TextDecoration.UNDERLINE;
	
	cfg.defaultLinkNormalFormat = normalTLF;
	cfg.defaultLinkHoverFormat = hoverTLF;
	cfg.defaultLinkActiveFormat = activeTLF;
	TextFlow.defaultConfiguration = cfg;
}

private var ignoreKeyboard : Boolean; 

private function onPopUp( e : PopUpEvent ) : void
{
	ignoreKeyboard = e.numWindows > 0;
}

private function onAddedToStage() : void
{
	stage.addEventListener( KeyboardEvent.KEY_UP, onKeyUp );
}

private function onKeyUp( e : KeyboardEvent ) : void
{
	if ( ignoreKeyboard || ( stage.focus != null ) )
		return;
	
	//ctrl + c - copy
	if ( e.ctrlKey && e.keyCode == Keyboard.C )
	{
		s.copySelectedSamples();
		return;
	}
	
	//ctrl + v - paste
	if ( e.ctrlKey && e.keyCode == Keyboard.V )
	{
		s.pasteFromClipboard();
		return;
	}
	
	//ctrl + x - cut
	if ( e.ctrlKey && e.keyCode == Keyboard.X )
	{
		s.cutSelectedSamples();
		return;
	}
	
	//ctrl + a - select all
	if ( e.ctrlKey && e.keyCode == Keyboard.A )
	{
		s.selectAllSamples();
		return;
	}
	
	//ctrl + i - invert selected samples
	if ( e.ctrlKey && e.keyCode == Keyboard.I )
	{
		s.invertSelectedSamples();
	}
	
	//ctrl + l - loop on/of selected samples
	if ( e.ctrlKey && e.keyCode == Keyboard.L )
	{
		s.automaticTuneOnOffSelectedSamples();
	}
	
	if ( e.ctrlKey && e.keyCode == Keyboard.F )
	{
		ApplicationModel.fullScreen = ! ApplicationModel.fullScreen;
		return;
	}
	
	//del - delete
	if ( e.keyCode == Keyboard.DELETE && ! e.ctrlKey && ! e.shiftKey && ! e.altKey )
	{
		s.deleteSelectedSamples();
		return;
	}
	
	//play/stop
	if ( e.keyCode == Keyboard.SPACE )
	{
		if ( s.numTracks > 0 )
		{
			if ( s.playing ) s.stop();
			 else s.play();	
		}
		
		return;
	}
	
	if ( e.keyCode == Keyboard.LEFT )
	{
		s.gotoPrevBar();
		return;
	}
	
	if ( e.keyCode == Keyboard.RIGHT )
	{
		s.gotoNextBar();
		return;
	}
	
	if ( e.keyCode == Keyboard.Z && e.ctrlKey )
	{
		if ( History.isCanUndo() )
		{
			History.undo();
		}
	}
	
	if ( e.keyCode == Keyboard.Y && e.ctrlKey )
	{
		if ( History.isCanRedo() )
		{
			History.redo();
		}
	}
}
	
