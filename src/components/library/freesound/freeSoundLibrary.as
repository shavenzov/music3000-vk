import components.library.freesound.FreeSoundPlayer;

import flash.events.Event;
import flash.events.ProgressEvent;

import mx.collections.AsyncListView;
import mx.collections.errors.ItemPendingError;
import mx.core.ClassFactory;

import org.freesound.Sound;

import spark.events.IndexChangeEvent;

private var sd : AsyncSoundCollection = new AsyncSoundCollection();
private var alv : AsyncListView;


private function init() : void
{
	alv = new AsyncListView( sd );
    result.dataProvider = alv;
	sd.addEventListener( ProgressEvent.PROGRESS, onLoadingData );
	sd.addEventListener( Event.COMPLETE, onLoadedData );
	alv.createPendingItemFunction = handleCreatePendingItemFunction;
}	

private function listChanged( e : IndexChangeEvent ) : void
{
	/*releaseListenersForSound();
	
	params.includeInLayout = ( e.newIndex != -1 );
	
	if ( params.includeInLayout )
	{
		var s : org.freesound.Sound = result.selectedItem as org.freesound.Sound;
	}
	
	params.includeInLayout = ( s != null );
	
	if ( params.includeInLayout )
	{
		if ( s.analysis )
		{
			updateParams( s );
		}
		else
		{
		  setListenersForSound( s );	
		}	
	}
	
	params.visible = params.includeInLayout;*/
}

private function updateParams( s : org.freesound.Sound ) : void
{
	asSample.selected = s.analysis.rhythm.bpm > 40;
	bpm.value = s.analysis.rhythm.bpm;
}	

private function onGotSoundAnalysis( e  : Event ) : void
{
	updateParams( lastSelected );
	releaseListenersForSound();
}	

private var lastSelected : org.freesound.Sound;

private function setListenersForSound( s : org.freesound.Sound ) : void
{
	if ( lastSelected ) return;
	
	lastSelected = s;
	s.addEventListener( "GotSoundAnalysis", onGotSoundAnalysis );
}

private function releaseListenersForSound() : void
{
	if ( ! lastSelected ) return;
	
	lastSelected.removeEventListener( "GotSoundAnalysis", onGotSoundAnalysis );
	lastSelected = null;
}	

private function onLoadingData( e : Event ) : void
{
	progress.includeInLayout = progress.visible = true;
}

private function onLoadedData( e : Event ) : void
{
   progress.includeInLayout = progress.visible = false; 	
}	

private function selectRenderer( item : Object ) : ClassFactory
{
	if ( item is ItemPendingError )
	{
		return new ClassFactory( PendingItemRenderer );
	}
	
	if ( item is org.freesound.Sound )
	{
		return new ClassFactory( SoundRenderer );
	}
	
	return null;
}	

private function handleCreatePendingItemFunction(index:int, ipe:ItemPendingError):Object {
	return ipe;
}

private function go( str : String ) : void
{
	result.scroller.verticalScrollBar.value = 0;
	FreeSoundPlayer.cash.clear();
	sd.getSoundsFromQuery( { q : str } );
}	