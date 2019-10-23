import classes.Sequencer;
import classes.SequencerImplementation;
import classes.events.ChangeBPMEvent;

import com.audioengine.sequencer.Sequencer;
import com.audioengine.sequencer.events.SequencerEvent;

import components.sequencer.VisualSequencer;
import components.sequencer.events.ProjectEvent;
import components.sequencer.timeline.MeasureType;

import flash.events.Event;
import flash.events.FullScreenEvent;
import flash.events.IEventDispatcher;
import flash.events.MouseEvent;
import flash.utils.clearInterval;
import flash.utils.setInterval;

import mx.managers.history.History;
import mx.managers.history.HistoryOperation;
import mx.managers.history.HistoryRecord;

private var _vs : VisualSequencer;
private var seq : SequencerImplementation;

private var nextTimerID : int = -1;
private var direction   : int;

private function libraryButtonClick() : void
{
	ApplicationModel.library.show();
}

private function closeButtonClick() : void
{
	ApplicationModel.library.hide();
}

private function tick() : void
{
	if ( direction == 1 )
	{
		_vs.gotoNextBar();
	}
	else
	{
		vs.gotoPrevBar();
	}
}

private function startTimer() : void
{
	tick();
	
	if ( nextTimerID == -1 )
	{
		nextTimerID = setInterval( tick, 150 );
		stage.addEventListener( MouseEvent.MOUSE_UP, onStageMouseUp );
	}
}

private function stopTimer() : void
{
	if ( nextTimerID != -1 )
	{
	  clearInterval( nextTimerID );
	  nextTimerID = -1;
	  stage.removeEventListener( MouseEvent.MOUSE_UP, onStageMouseUp );
	}
}

private function fastBackwardStart() : void
{
	if ( _vs.numTracks > 0 )
	{
		direction = -1;
		startTimer();	
	}
}

private function onStageMouseUp( e : MouseEvent ) : void
{
	stopTimer();
}

private function fastForwardStart() : void
{
	if ( _vs.numTracks > 0 )
	{
		direction = 1;
		startTimer();
	}
}

private function onInit() : void
{
	ApplicationModel.bottomPanel = this;
	seq = classes.Sequencer.impl;
}

private function creationComplete() : void
{
	display.bpm      = _vs.bpm;
	display.position = _vs.position;
	updateFullScreenButtonToolTip();
	updateRepeatButtonToolTip();
}

private function setListeners( obj : IEventDispatcher ) : void
{
	obj.addEventListener( SequencerEvent.START_PLAYING, onStartPlaying );
	obj.addEventListener( SequencerEvent.STOPPED, onStopped );
	obj.addEventListener( SequencerEvent.POSITION_CHANGED, onPositionChanged );
	obj.addEventListener( ChangeBPMEvent.BPM_CHANGED, onBPMChanged );
	obj.addEventListener( SequencerEvent.LOOP_CHANGED, onLoopChanged );
	obj.addEventListener( ProjectEvent.END_UPDATE, onProjectEndUpdate );
	obj.addEventListener( SequencerEvent.CLEAR, onLoopChanged );
}

private function unsetListeners( obj : IEventDispatcher ) : void
{
	obj.removeEventListener( SequencerEvent.START_PLAYING, onStartPlaying );
	obj.removeEventListener( SequencerEvent.STOPPED, onStopped );
	obj.removeEventListener( SequencerEvent.POSITION_CHANGED, onPositionChanged );
	obj.removeEventListener( ChangeBPMEvent.BPM_CHANGED, onBPMChanged );
	obj.removeEventListener( SequencerEvent.LOOP_CHANGED, onLoopChanged );
	obj.removeEventListener( ProjectEvent.END_UPDATE, onProjectEndUpdate );
	obj.removeEventListener( SequencerEvent.CLEAR, onLoopChanged );
}

private function viewTypeChanged() : void
{
	if ( display.timeInMeasures )
	{
		_vs.viewType = MeasureType.MEASURES; 
	}
	else
	{
		_vs.viewType = MeasureType.SECONDS;
	}
}

private function onBPMCompleteChange( e : ChangeBPMEvent ) : void
{
	History.add( new HistoryRecord( new HistoryOperation( seq, seq.changeBPMTo, e.oldBPM ),
		new HistoryOperation( seq, seq.changeBPMTo, e.newBPM ),
		'Отменить изменение темпа','Изменить темп на ' + e.newBPM.toString() ) );
}

private function onBPMChangedByDisplay() : void
{
	_vs.bpm = display.bpm;
}

private function onBPMChanged( e : ChangeBPMEvent ) : void
{
	display.bpm = e.newBPM;
}

private function onPositionChanged( e : SequencerEvent ) : void
{
	display.position = e.pos;
}

private function updateButtons() : void
{
	playButton.visible = playButton.includeInLayout = ! _vs.playing;
	stopButton.visible = stopButton.includeInLayout = _vs.playing;
}

private function onStartPlaying( e : SequencerEvent ) : void
{
	updateButtons();
}

private function onStopped( e : SequencerEvent ) : void
{
	updateButtons();
}

private function playClick() : void
{
	if ( ( _vs.numTracks > 0 ) && ( ! _vs.playing ) )
	{
		_vs.play();	
	}
}

private function stopClick() : void
{
	_vs.stop();
}

public function get vs() : VisualSequencer
{
	return _vs;
}

public function set vs( value : VisualSequencer ) : void
{
	if ( _vs != value )
	{
	    if ( _vs ) unsetListeners( _vs );
		_vs = value;
		setListeners( _vs );
	}
}

private function prevClick() : void
{
	_vs.gotoStart();
}

private function repeatClick() : void
{
	if ( _vs.numTracks == 0 )
	{
		repeatButton.selected = false;
		return;
	}
	
	_vs.loop = repeatButton.selected;
    updateRepeatButtonToolTip();
}

private function fullScreenClick() : void
{
	ApplicationModel.fullScreen = fullScreenButton.selected;
}

private function onAddedToStage() : void
{
	stage.addEventListener( FullScreenEvent.FULL_SCREEN, onFullScreen );
}

private function onFullScreen( e : FullScreenEvent ) : void
{
	fullScreenButton.selected = e.fullScreen;
	updateFullScreenButtonToolTip();
}

private function updateFullScreenButtonToolTip() : void
{
	if ( fullScreenButton.selected )
	{
		fullScreenButton.toolTip = 'Выйти из полноэкранного режима';
	}
	else
	{
		fullScreenButton.toolTip = 'Перейти в полноэкранный режим';
	}
}

private function updateRepeatButtonToolTip() : void
{
	if ( _vs.loop )
	{
		repeatButton.toolTip = 'Отключить режим повторения';
	}
	else
	{
		repeatButton.toolTip = 'Включить режим повторения';
	}
}

private function onLoopChanged( e : Event ) : void
{
	repeatButton.selected = _vs.loop;
	updateRepeatButtonToolTip();
}

private function onProjectEndUpdate( e : Event ) : void
{
	onLoopChanged( null );
	display.timeInMeasures = ( _vs.viewType == MeasureType.MEASURES );	
}