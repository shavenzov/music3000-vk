import classes.SampleDescription;

import com.audioengine.core.TimeConversion;
import com.utils.FileUtils;

import components.sequencer.VisualSampleDragDropDummy;

import flash.events.MouseEvent;

import mx.core.DragSource;
import mx.managers.DragManager;

import org.freesound.Sound;
import org.freesound.SoundLoader;

private static const soundLoader : SoundLoader = new SoundLoader();

private var infoLoading     : Boolean;
private var analysisLoading : Boolean;

private function clearView() : void
{
	original_filename.text = '';
	waveform.clear();
	
	var s : org.freesound.Sound = super.data as org.freesound.Sound;
	
	if ( s )
	{
		if ( infoLoading )
		{
			releaseInfoListeners( s );
		}
		
		if ( analysisLoading )
		{
			releaseAnalysisListeners( s );
		}	
		
		soundLoader.cancel( s );
	}	
}	

private function onGotSoundInfo( e : Event ) : void
{
	description.htmlText = data.info[ 'description' ];
	releaseInfoListeners( org.freesound.Sound ( e.currentTarget ) );
}

private function onErrorSoundInfo( e : IOErrorEvent ) : void
{
	description.text = 'error...';
	releaseInfoListeners( org.freesound.Sound ( e.currentTarget ) );
}

private function onGotSoundAnalysis( e : Event ) : void
{
	bpm.text = '/' + data.analysis.rhythm.bpm.toString();
	releaseAnalysisListeners( org.freesound.Sound ( e.currentTarget ) );
}

private function onErrorSoundAnalysis( e : IOErrorEvent ) : void
{
	bpm.text = '???';
	releaseAnalysisListeners( org.freesound.Sound ( e.currentTarget ) );
}	

private function setInfoListeners( s : org.freesound.Sound ) : void
{
	s.addEventListener( "GotSoundInfo", onGotSoundInfo );
	s.addEventListener( "ErrorSoundInfo", onErrorSoundInfo );
	infoLoading = true;
}

private function setAnalysisListeners( s : org.freesound.Sound ) : void
{
	s.addEventListener( "GotSoundAnalysis", onGotSoundAnalysis );
	s.addEventListener( "ErrorSoundAnalysis", onErrorSoundAnalysis );
	analysisLoading = true;
}	

private function releaseAnalysisListeners( s : org.freesound.Sound ) : void
{
	s.removeEventListener( "GotSoundAnalysis", onGotSoundAnalysis );
	s.removeEventListener( "ErrorSoundAnalysis", onErrorSoundAnalysis );
	analysisLoading = false;
}	

private function releaseInfoListeners( s : org.freesound.Sound ) : void
{
	s.removeEventListener( "GotSoundInfo", onGotSoundInfo );
	s.removeEventListener( "ErrorSoundInfo", onErrorSoundInfo );
	infoLoading = false;
}	

override public function set data( value : Object ) : void
{
	if ( value == data ){ trace( 'value == data' ); return; }
	
	clearView();
	
	super.data = value;
	
	if ( ! value ) return;
	
	if ( value.info )
	{
		var s : org.freesound.Sound = org.freesound.Sound( value );
		
		if ( ! s.fullSoundLoaded )
		{
			setInfoListeners( s );
			soundLoader.loadInfo( s );
			description.text = 'loading...';
		}
		else
		{
			description.htmlText = s.info[ 'description' ];
		}	
		
		if ( ! s.soundAnalysis )
		{
			setAnalysisListeners( s );
			soundLoader.loadAnalysis( s );
			
			bpm.text = '/---';
		}
		else
		{
			bpm.text = '/' + s.analysis.rhythm.bpm.toString();
		}	
		
		original_filename.text = FileUtils.removeFileExtension( s.info[ 'original_filename' ] );
		
		//sound player
		waveform.soundwavePath = s.info[ 'waveform_m' ];
		waveform.duration = s.info[ 'duration' ] * 1000;
		waveform.url = s.info[ 'preview-hq-mp3' ];
	}
}

override protected function startDragging( event : MouseEvent ) : void
{
	var sound : org.freesound.Sound = org.freesound.Sound( data );
	
	if ( sound.analysis && sound.analysis.rhythm )
	{
		var s : SampleDescription = new SampleDescription( sound.info[ 'id' ], sound.info[ 'preview-hq-mp3' ],
			                                               sound.info[ 'original_filename' ], sound.info[ 'duration' ], 
														   sound.analysis.rhythm.bpm, sound.info[ 'description' ], sound.info.user[ 'username' ], null, null, 
														   sound.analysis.rhythm.bpm > 40 );
														   
		
		var dragImage  : VisualSampleDragDropDummy = new VisualSampleDragDropDummy();
		dragImage.data = s;
		dragImage.originalColor = 0x0099FF;
		
		//var initEvent : MouseEvent = new MouseEvent( event.type, event.bubbles, event.cancelable, , event.stageY, event.relatedObject );	
		
		var dragSource : DragSource = new DragSource();
		dragSource.addData( s, 'sample' );
		dragSource.addData( dragImage, 'dragImage' );
		
		DragManager.doDrag( this, dragSource, event, dragImage, 0, 0, 1 );
	}	
}	