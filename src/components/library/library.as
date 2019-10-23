 import flash.events.Event;
 import flash.geom.Rectangle;
 
 import mx.controls.Button;
 import mx.core.UIComponent;
 import mx.core.mx_internal;
 import mx.effects.Tween;
 import mx.events.FlexEvent;
 import mx.utils.StringUtil;
 
 import spark.events.TextOperationEvent;
 
 import components.controls.SearchTextInput;
 import components.controls.events.SearchtextInputEvent;
 import components.library.ILibraryModule;

use namespace mx_internal;

private static const TWEEN_DURATION : Number = 250;

private var tween : Tween;

private var searchBox   : SearchTextInput;
private var bottomPanel : BottomPanel;

private static const FROM_HIDE_TO_SHOW : int = 10;
private static const FROM_SHOW_TO_HIDE : int = 20;
private static const FROM_SHOW_TO_SHOW : int = 30;

private var cAction : int = FROM_HIDE_TO_SHOW;

public function get animation() : Boolean
{
	return tween != null;
}

private function setEffect( set : Boolean ) : void
{
	var i : int = 0;
	
	while( i < viewStack.numChildren )
	{
		var child : UIComponent = UIComponent( viewStack.getChildAt( i ) );
		    child.setStyle( 'showEffect', set ? Show : null );
			child.setStyle( 'hideEffect', set ? Hide : null );
		
		i ++;
	}
}

private var _viewIndex : int;

private function onContentCreated( e : FlexEvent ) : void
{
	viewStack.removeEventListener( e.type, onContentCreated );
	show( _viewIndex );
}

private function onContentCreationComplete( e : FlexEvent ) : void
{
	viewStack.selectedChild.removeEventListener( e.type, onContentCreationComplete )
	showSearchBox();
}

private var boxTweenAlpha : Tween;
private var boxTweenY     : Tween;   

private function resetSearchBoxTween() : void
{
	if ( boxTweenAlpha )
	{
		boxTweenAlpha.stop();
		boxTweenAlpha = null;
	}
	
	if ( boxTweenY )
	{
		boxTweenY.stop();
		boxTweenY = null;
	}
}

private function onSearchBoxReset( e : SearchtextInputEvent ) : void
{
	var m : ILibraryModule = ILibraryModule( viewStack.selectedChild );
	    m.reset();
}

private function onSearchBoxEnter( e : FlexEvent ) : void
{
	searchBox.text = StringUtil.trim( searchBox.text );
	
	var m : ILibraryModule = ILibraryModule( viewStack.selectedChild );
	
	m.searchText = searchBox.text;
	m.search();
}

private function onSearchTextChanged( e : TextOperationEvent ) : void
{
	ILibraryModule( viewStack.selectedChild ).searchText = StringUtil.trim( searchBox.text );
}

private function onSearchBoxEnabledChanged() : void
{
	var m : ILibraryModule = ILibraryModule( viewStack.selectedChild );
	
	searchBox.visible = m.searchBoxEnabled;
}

private function showSearchBox() : void
{
	resetSearchBoxTween();
	
	var m : ILibraryModule = ILibraryModule( viewStack.selectedChild );
	
	searchBox.text = m.searchText;
	
	var newSearchBoxPos : Number = getSearchBoxPos();
	
	searchBox.visible = m.searchBoxEnabled;
	
	if ( cAction == FROM_HIDE_TO_SHOW )
	{
		bottomPanel.libraryButton.visible = false;
		searchBox.alpha = 0;
		searchBox.enabled = false;
		searchBox.addEventListener( FlexEvent.ENTER, onSearchBoxEnter );
		searchBox.addEventListener( SearchtextInputEvent.RESET, onSearchBoxReset );
		searchBox.addEventListener( TextOperationEvent.CHANGE, onSearchTextChanged );
		
		boxTweenAlpha = new Tween( this, searchBox.alpha, 1.0, TWEEN_DURATION, -1, onSearchBoxUpdateAlpha, onEndSearchBoxAnimationAlpha );
		boxTweenY     = new Tween( this, getStartBoxPos(), newSearchBoxPos, TWEEN_DURATION, -1, onSearchBoxUpdateY, onEndSearchBoxAnimationY );
	}
	else 
	{
		if ( newSearchBoxPos != searchBox.left )
		{
			boxTweenY  = new Tween( this, searchBox.left, newSearchBoxPos, TWEEN_DURATION, -1, onSearchBoxUpdateY, onEndSearchBoxAnimationY );
		}
		else
		{
			onEndSearchBoxAnimationY( newSearchBoxPos );
		}
	}
}

private function onSearchBoxUpdateAlpha( value : Number ) : void
{
	searchBox.alpha = value;
}

private function onSearchBoxUpdateY( value : Number ) : void
{
	searchBox.left = value;
}

private function onEndSearchBoxAnimationAlpha( value : Number ) : void
{
	boxTweenAlpha = null;	
}

private function onEndSearchBoxAnimationY( value : Number ) : void
{
	boxTweenY = null;
	
	if ( cAction == FROM_SHOW_TO_HIDE )
	{
		bottomPanel.libraryButton.visible = true;
		searchBox.alpha = 0.0;
		searchBox.visible = false;
	}
	else
	{
		bottomPanel.closeButton.enabled = true;
		
		if ( cAction == FROM_HIDE_TO_SHOW )
		{
			bottomPanel.closeButton.visible = true;
			searchBox.enabled = true;
			
			onStageResized( null );
			stage.addEventListener( Event.RESIZE, onStageResized );
		}
	}
}

private function onStageResized( e : Event ) : void
{
	searchBox.left = getSearchBoxPos();
}

private function hideSearchBox() : void
{
	stage.removeEventListener( Event.RESIZE, onStageResized );
	searchBox.removeEventListener( FlexEvent.ENTER, onSearchBoxEnter );
	searchBox.removeEventListener( SearchtextInputEvent.RESET, onSearchBoxReset );
	searchBox.removeEventListener( TextOperationEvent.CHANGE, onSearchTextChanged );
	
	bottomPanel.closeButton.visible = false;
	searchBox.enabled = false;
	
	resetSearchBoxTween();
	
	boxTweenAlpha = new Tween( this, searchBox.alpha, 0.0, TWEEN_DURATION, -1, onSearchBoxUpdateAlpha, onEndSearchBoxAnimationAlpha );
	boxTweenY     = new Tween( this, getSearchBoxPos(), getStartBoxPos(), TWEEN_DURATION, -1, onSearchBoxUpdateY, onEndSearchBoxAnimationY );
}

private function getStartBoxPos() : Number
{
	var rect : Rectangle = bottomPanel.closeButton.getBounds( bottomPanel );
	
	return rect.x - searchBox.getExplicitOrMeasuredWidth() + rect.width;
}

private function getSearchBoxPos() : Number
{
	var mc   : ILibraryModule = ILibraryModule( viewStack.selectedChild );
	var rect : Rectangle = mc.mainComponent.getBounds( bottomPanel );
	
	return rect.x + 10 + ( rect.width - searchBox.getExplicitOrMeasuredWidth() ) / 2;
}

public function show( viewIndex : int = -1 ) : void
{
	if ( viewIndex == -1 )
	{
		viewIndex = viewStack.selectedIndex;
	}
	
	if ( ! viewStack.deferredContentCreated )
	{
		_viewIndex = viewIndex;
		viewStack.addEventListener( FlexEvent.CONTENT_CREATION_COMPLETE, onContentCreated );
		viewStack.createDeferredContent();
		return;
	}
	
   if ( ! visible || ( viewIndex != viewStack.selectedIndex ) )
   {
	   cAction = visible ? FROM_SHOW_TO_SHOW : FROM_HIDE_TO_SHOW;
	   
	   setEffect( visible );
	   
	   includeInLayout = true;
	   visible = true;
	   
	   if ( tween )
	   {
		   tween.stop();
		   tween = null;
	   }
	   
	   var fromModule : ILibraryModule = ILibraryModule( viewStack.selectedChild );
	   
	   viewStack.selectedIndex = viewIndex;
	   
	   var toModule : ILibraryModule = ILibraryModule( viewStack.selectedChild );
	   
	   //Обновляем результаты поиска если изменилось св-во showOnlyFavorite
	   if ( fromModule.showOnlyFavorite != toModule.showOnlyFavorite )
	   {
		   toModule.showOnlyFavorite = fromModule.showOnlyFavorite;
		   
		   if ( toModule.ready )
		   {
			   toModule.search();   
		   }
	   }
	   
	   checkButtonPage( viewIndex );
	   pages.enabled = false;
	   tween = new Tween( this, height, viewStack.selectedChild.height, TWEEN_DURATION );
   }
}

private function checkButtonPage( index : int ) : void
{
	for ( var i : int = 0; i < pages.numElements; i ++ )
	{
		var b : Button = pages.getElementAt( i ) as Button;
		
		if ( b )
		{
			b.selected = index == i;	
		}
	}
}

public function hide() : void
{
	if ( visible )
	{
		cAction = FROM_SHOW_TO_HIDE;
		
		if ( tween )
		{
			tween.stop();
			tween = null;
		}
		
		tween = new Tween( this, height, 0, TWEEN_DURATION );
		
		hideSearchBox();
	}
}

mx_internal function onTweenUpdate(value:Number):void
{
	height = value;
}

mx_internal function onTweenEnd( value:Number ) : void
{
	height = value;
	
	if ( cAction == FROM_SHOW_TO_HIDE )
	{
		includeInLayout = false;
		visible = false;
		
		dispatchEvent( new FlexEvent( FlexEvent.HIDE ) );
	}
	else
	{
		/*trace( 'component initialized =', UIComponent( viewStack.selectedChild ).initialized );
		trace( 'defered content created =', viewStack.selectedChild.deferredContentCreated );
		viewStack.selectedChild.addEventListener( FlexEvent.INITIALIZE, function(){trace( 'initialize' )} );
		viewStack.selectedChild.addEventListener( FlexEvent.PREINITIALIZE, function(){trace( 'preinitialize' )} );
		viewStack.selectedChild.addEventListener( FlexEvent.CREATION_COMPLETE, function(){trace( 'creation complete' )} );
		viewStack.selectedChild.addEventListener( ResizeEvent.RESIZE, function(){trace( 'resize' )} );
		viewStack.selectedChild.addEventListener( FlexEvent.UPDATE_COMPLETE, function(){trace( 'update complete' )} );
		viewStack.selectedChild.addEventListener( FlexEvent.VALUE_COMMIT, function(){trace( 'value commit' )} );
		viewStack.selectedChild.addEventListener( FlexEvent.CONTENT_CREATION_COMPLETE, function(){trace( 'content creation complete' )} );*/
		
		if ( UIComponent( viewStack.selectedChild ).initialized && viewStack.selectedChild.deferredContentCreated )
		{
			showSearchBox();
		}
		else
		{
			bottomPanel.closeButton.enabled = false;
			viewStack.selectedChild.addEventListener( FlexEvent.UPDATE_COMPLETE, onContentCreationComplete );
		}
		
		dispatchEvent( new FlexEvent( FlexEvent.SHOW ) );
	}
	
	pages.enabled = true;
	tween = null;
}

private function onCreationComplete() : void
{
	ApplicationModel.library = this;
	bottomPanel = ApplicationModel.bottomPanel;
	searchBox = ApplicationModel.bottomPanel.searchBox;
}

private function onShowOnlyFavoriteButtonClick() : void
{
	var m : ILibraryModule = ILibraryModule( viewStack.selectedChild );
	    m.showOnlyFavorite = showOnlyFavorite.selected;
		m.search();
}