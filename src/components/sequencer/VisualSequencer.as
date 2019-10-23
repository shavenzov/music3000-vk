package components.sequencer
{
	import com.audioengine.core.AudioData;
	import com.audioengine.core.TimeConversion;
	import com.audioengine.sequencer.events.SequencerEvent;
	import com.utils.TimeUtils;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.system.System;
	
	import mx.core.UIComponent;
	import mx.events.DragEvent;
	import mx.events.FlexEvent;
	import mx.events.PropertyChangeEvent;
	import mx.managers.DragManager;
	import mx.managers.history.History;
	import mx.managers.history.HistoryOperation;
	import mx.managers.history.HistoryRecord;
	
	import classes.SequencerImplementation;
	import classes.events.ChangeBPMEvent;
	import classes.events.CreateTrackEvent;
	import classes.events.SequencerEventPositionChangedBy;
	
	import components.sequencer.clipboard.Clipboard;
	import components.sequencer.controls.ControlContainer;
	import components.sequencer.controls.TrackControlGroup;
	import components.sequencer.events.ProjectEvent;
	import components.sequencer.timeline.IPosition;
	import components.sequencer.timeline.IScale;
	import components.sequencer.timeline.MeasureType;
	import components.sequencer.timeline.ScrollableTimeLine;
	import components.sequencer.timeline.TimeLine;
	import components.sequencer.timeline.TimeLineParameters;
	import components.sequencer.timeline.TimeLineScrollMode;
	import components.sequencer.timeline.events.MarkerChangeEvent;
	import components.sequencer.timeline.events.MarkerEvent;
	import components.sequencer.timeline.events.SelectionSampleEvent;
	import components.sequencer.timeline.events.TracingEvent;
	import components.sequencer.timeline.visual_sample.BaseVisualSample;
	
	[Event(type="com.audioengine.sequencer.events.SequencerEvent", name="START_RECORDING")]
	[Event(type="com.audioengine.sequencer.events.SequencerEvent", name="START_PLAYING")]
	[Event(type="com.audioengine.sequencer.events.SequencerEvent", name="STOPPED")]
	[Event(type="com.audioengine.sequencer.events.SequencerEvent", name="POSITION_CHANGED")]
	[Event(type="classes.events.ChangeBPMEvent", name="BPM_CHANGED")]
	
	public class VisualSequencer extends UIComponent implements IScale, IPosition
	{
		[Embed(source='/assets/assets.swf', symbol='ruller_background')]
		private static const RullerBackground : Class;
		
		private var _bg1 : Sprite;
		private var _bg  : Background;
		private var _timeLineContainer : ScrollableTimeLine;
		private var _controls : TrackControlGroup;
		
		/**
		 * Как отображать значения на рулетке
		 * MeasureType.MEASURES - в тактах
		 * MeasureType.SECONDS  - в секундах  
		 */		
		private var _viewType : int = MeasureType.MEASURES;
		
		/**
		 * Как отображать сетку
		 * MeasureType.MEASURES - в тактах
		 * MeasureType.SECONDS  - в секундах 
		 */		
		private var _measureType : int = MeasureType.MEASURES;
		
		/**
		 * Скорость воспроизведения ( ударов в минуту ) 
		 */		
		private var _bpm : Number = 128.0;
		
		/**
		 *Масштаб Количество секунд в пикселе
		 *Это значение используется для определения длины трека по умолчанию на основании _duration 
		 */
		private var _scale        : Number  = 100.0;
		
		/**
		 *Длина объекта в секундах 
		 * 
		 */
		private var _duration        : Number  = 3 * AudioData.RATE;
		
		/**
		 * Отображать ли маркеры "петли" 
		 */
		private var _loop : Boolean;
		
		/**
		 * Отображать ли маркер установки длины микса 
		 */		
		private var _durationMarker : Boolean = true;
		
		/**
		 * Изменилось значение стартовой границы петли 
		 */		
		private var _startPositionChanged : Boolean;
		/**
		 * Изменилось значение конечной границы петли 
		 */		
		private var _endPositionChanged   : Boolean;
		
		/**
		 * Флаг изменения положения маркера воспроизведения 
		 */		
		private var _positionChanged : Boolean;
		/**
		 * Флаг изменения позиции секвенсором 
		 */		
		private var _positionChangedBySeq : Boolean;
		/**
		 * флаг захвата головки воспроизведения 
		 */		
		private var _playHeadCaptured  : Boolean; 
		
		/**
		 * Ссылка на синглтон управления секвенсором 
		 */		
		private var _seq : SequencerImplementation;
		
		/**
		 * Текущая выбранная дорожка 
		 */		
		private var _selectedTrack : int = -1;
		
		/**
		 * В данный момент проиходит перетаскивание дорожки 
		 */		
		private var _trackDragging : Boolean;
		/**
		 * номер текущей дорожки над которой сейчас находится курсор во время перетаскивания дорожки 
		 */		
		private var _emptyTrackPos : int;
		private var _lastTrackPos  : int;
		/**
		 * Номер дорожки до момента перетаскивания 
		 */		
		private var _startTrackPos : int;
		
		/**
		 * В данный момент происходит редактирование границ петли 
		 */		
		private var _loopEditing : Boolean;
		
		/**
		 * Вкл/выкл режим автоматической прокрутки во время воспроизведения 
		 */		
		private var autoScroll : Boolean = true;
		
		/**
		 * Текущий режим прокрутки относительно курсора 
		 */		
		private var cScrollMode : int = TimeLineScrollMode.SCROLL_ON_NEXT_VIEW;
		
		/**
		 * Ссылка на timeline 
		 */		
		public var timeline : TimeLine;
		
		public function VisualSequencer()
		{
			super();
			focusEnabled = false;
			tabEnabled = false;
			
			_seq = classes.Sequencer.impl;
			
			_seq.duration = _duration;
			
			_seq.addEventListener( SequencerEvent.POSITION_CHANGED, onPositionChanged );
			_seq.addEventListener( SequencerEvent.START_PLAYING, onStartPlaying );
			_seq.addEventListener( SequencerEvent.START_RECORDING, onStartRecording );
			_seq.addEventListener( SequencerEvent.STOPPED, onStopped );
			_seq.addEventListener( ChangeBPMEvent.BPM_CHANGED, onBPMChanged );
			_seq.addEventListener( SequencerEvent.ADD_SAMPLE, onSomeSampleChanged );
			_seq.addEventListener( SequencerEvent.REMOVE_SAMPLE, onSomeSampleChanged );
			_seq.addEventListener( SequencerEvent.SAMPLE_CHANGE, onSomeSampleChanged );
			_seq.addEventListener( SequencerEvent.MIXER_PARAM_CHANGED, onSomethingChanged );
			_seq.addEventListener( SequencerEvent.LOOP_CHANGED, onSomeSampleChanged );
			_seq.addEventListener( SequencerEvent.DURATION_CHANGED, onSomethingChanged );
			_seq.addEventListener( SequencerEvent.PALETTE_COMPACTED, onSomethingChanged );
			
			//Вызывается, при завершении загрузки микса
			addEventListener( ProjectEvent.END_UPDATE, onProjectEndUpdate );
			
			/*
			_seq.addEventListener( SequencerEvent.END, onEnd );
			_seq.addEventListener( SequencerEvent.END_MUSIC, onEnd );
			*/
			
			_seq.addEventListener( CreateTrackEvent.CREATE_TRACK, onCommandCreateTrack );
			
			scale = TimeLineParameters.DEFAULT_SCALE;
			measureType = MeasureType.MEASURES;
			viewType    = MeasureType.MEASURES;
			timeDuration = Settings.DEFAULT_PROJECT_DURATION;
		}
		
		/**
		 * Игнорировать изменения 
		 */		
		private var _ignoreChanges : Boolean;
		
		public function get ignoreChanges() : Boolean
		{
			return _ignoreChanges;
		}
		
		public function set ignoreChanges( value : Boolean ) : void
		{
			if ( _ignoreChanges != value )
			{
				_ignoreChanges = value;
				_seq.ignoreChanges = value;
				History.enabled = ! value;
			}
		}
		
		private function updateDurationMarkerLeftBorder() : void
		{
			var end : Number = _loop ? ( _seq.realEnd > _seq.endPosition ? _seq.realEnd : _seq.endPosition  ) : _seq.realEnd;
			
			if ( end < TimeLineParameters.MIN_DURATION )
			{
				end = TimeLineParameters.MIN_DURATION;
			}
			
			//timeline._markers._durationHead.leftBorder = TimeConversion.roundNumSamplesToWholeBar( end , _bpm );
		}
		
		private function onProjectEndUpdate( e : Event ) : void
		{
			updateDurationMarkerLeftBorder();
		}
		
		private function onSomeSampleChanged( e : SequencerEvent ) : void
		{
			if ( ! _ignoreChanges )
			{
				updateDurationMarkerLeftBorder();
				dispatchEvent( e );
			}
		}
		
		private function onSomethingChanged( e : SequencerEvent ) : void
		{
			if ( ! _ignoreChanges )
			  dispatchEvent( e );
		}
		
		private function onBPMChanged( e : ChangeBPMEvent ) : void
		{
			_bpm = e.newBPM;
			invalidateProperties();
			validateProperties();
			dispatchEvent( e );
		}
		
		private function onStartPlaying( e : SequencerEvent ) : void
		{
			dispatchEvent( e );
		}
		
		private function onStartRecording( e : SequencerEvent ) : void
		{
			dispatchEvent( e );
		}
		
		public function copySelectedSamples() : void{
			timeline.copySelectedSamples();
		}
		
		public function pasteFromClipboard( position : Number = -1 ) : void{
			
			//Если одна дорожка и она не выбрана, выбираем её
			if ( ( _selectedTrack == -1 ) && ( numTracks == 1 ) )
			{
				selectedTrack = 0;
			}
			
			timeline.pasteFromClipboard( position );
		}
		
		public function cutSelectedSamples() : void
		{
			timeline.cutSelectedSamples();
		}
		
		public function selectAllSamples() : void
		{
			timeline.selectAllSamples();
		}
		
		public function deleteSelectedSamples() : void
		{
			timeline.deleteSelectedSamples();
		}
		
		public function invertSelectedSamples() : void
		{
			timeline.invertSelectedSamples();
		}
		
		public function automaticTuneOnOffSelectedSamples() : void
		{
			timeline.automaticTuneOnOffSelectedSamples();
		}
		
		public function get seq() : SequencerImplementation
		{	
			return _seq;
		}
		
		public function get controls() : TrackControlGroup
		{
			return _controls;
		}	
		
		private function onCommandCreateTrack( e : CreateTrackEvent ) : void
		{
			createTrackAt( e.createAt, e.numTracks );
				
			/*add action to history*/
			History.add( new HistoryRecord( new HistoryOperation( this, removeTrackAt, e.createAt, e.numTracks ),
				                            new HistoryOperation( this, createTrackAt, e.createAt, e.numTracks )
											)
				       );
		}	
		
		private function onStopped( e : SequencerEvent ) : void
		{
			if ( ! _loop )
			{
				_positionChangedBySeq = true;
			    _positionChanged = true;
				
				invalidateProperties();
			}
			
			dispatchEvent( e );
		}	
		
		public function get viewType() : int
		{
			return _viewType;
		}
		
		public function set viewType( value : int ) : void
		{
			_viewType = value;
			invalidateProperties();
		}
		
		public function get measureType() : int
		{
			return _measureType;
		}
		
		public function set measureType( value : int ) : void
		{
			_measureType = value;
			invalidateProperties();
		}
		
		public function get bpm() : Number
		{
			return _bpm;
		}
		
		public function set bpm( value : Number ) : void
		{
			_bpm = value;
			_seq.bpm = value;
			invalidateProperties();
		}	
		
		private function onPositionChanged( e : SequencerEvent ) : void
		{
			if ( e.changedBy == SequencerEventPositionChangedBy.AUDIOENGINE )
			{
				if ( _playHeadCaptured )
				{
					_seq.position = timeline._markers.position;
				}	
				else
				{
					_positionChangedBySeq = true;	
				}	
				
				_positionChanged = true;
				
				invalidateProperties();
			}
		}	
		
		public function get position() : Number
		{
			return _seq.position;
		}
		
		public function set position( value : Number ) : void
		{
		  _seq.position = value;
		  _positionChanged = true;
		  invalidateProperties();	
		}
		
		public function get durationMarker() : Boolean
		{
			return _durationMarker;
		}
		
		public function set durationMarker( value : Boolean ) : void
		{
			_durationMarker= value;
			invalidateProperties();
		}
		
		public function get loop() : Boolean
		{
			return _seq.loop;
		}
		
		public function set loop( value : Boolean ) : void
		{
			_loop = value;
			_seq.loop = value;
			invalidateProperties();
		}
		
		public function get realDuration() : Number
		{
			return _seq.realDuration;
		}
		
		public function get startPosition() : Number
		{
			return _seq.startPosition;
		}
		
		public function set startPosition( value : Number ) : void
		{
			_seq.startPosition = value;
			_startPositionChanged = true;
			invalidateProperties();
		}
		
		public function get endPosition() : Number
		{
			return _seq.endPosition;
		}
		
		public function set endPosition( value : Number ) : void
		{
			_seq.endPosition = value;
			_endPositionChanged = true;
			invalidateProperties();
		}	
		
		public function get timePosition() : Number
		{
			return _seq.timePosition;
		}
		
		public function set timePosition( value : Number ) : void
		{
			_seq.timePosition = value;
			_positionChanged = true;
			invalidateProperties();
		}	
		
		public function get scale() : Number
		{
			return _scale;
		}
		
		public function set scale( value : Number ) : void
		{
			_scale = value;
			invalidateProperties();
		}
		
		public function get duration() : Number
		{
			return _duration;
		}
		
		public function set duration( value : Number ) : void
		{
			_duration = value;
			_seq.duration = value;
			invalidateProperties();
		}
		
		public function get timeDuration() : Number
		{
			return TimeConversion.numSamplesToSeconds( _duration );
		}
		
		public function set timeDuration( value : Number ) : void
		{
			duration = TimeConversion.secondsToNumSamples( value );
		}	
		
		public function get numTracks() : int
		{
			return _seq.numChannels;	
		}
		
		public function get actualSamples() : int
		{
			return _seq.actualSamples;
		}
		
		public function get numSamples() : int
		{
			return _seq.numSamples;
		}
		
		public function get numVisualSamples() :  int
		{
			return timeline.numSamples;
		}
		
		public function get selectedSamples() : int
		{
			return timeline.selectedSamples;
		}
		
		public function createTrack( name : String = null, type : String = null ) : void
		{
			_seq.createChannelAt();
			_controls.createTrackAt( _controls.numTracks, name, type );
			timeline.createTrackAt( timeline.numTracks );
		}	
		
		public function createTrackAt( index : int, n : int = 1 ) : void
		{
			var i : int = 0;
			
			while( i < n )
			{
				var cIndex : int = index + i;
				
				_seq.createChannelAt( cIndex );
				
				_controls.createTrackAt( cIndex );
				timeline.createTrackAt( cIndex );	
				
				i ++;
			}
			
			dispatchEvent( new CreateTrackEvent( CreateTrackEvent.CREATE_TRACK, index, n ) );
		}
		
		public function removeTrackAt( index : int, n : int = 1 ) : void
		{
			var i : int = 0;
			var end : int = index + n - 1;
			
			while( i < n )
			{
				var cIndex : int = end - i;
				
				timeline.removeTrackAt( cIndex );
				_controls.removeTrackAt( cIndex );
				_seq.removeChannelAt( cIndex );
				
				i ++;
			}
		}
		
		/**
		 * Удаляет все дорожки секвенсора 
		 * 
		 */		
		public function removeAllTracks() : void
		{
			removeTrackAt( 0, numTracks );
		}	
		
		override protected function createChildren() : void
		{
			super.createChildren();
			
			_bg1 = new RullerBackground();
			_bg1.alpha = 0.35;
			
			_bg = new Background();
			
			_timeLineContainer = new ScrollableTimeLine();
			_timeLineContainer.addEventListener( FlexEvent.INITIALIZE, onTimelineInitialized );
			
			_controls = new TrackControlGroup();
			_controls.addEventListener( MouseEvent.MOUSE_WHEEL, onControlsMouseWheel );
			
			addChild( _bg );
			addChild( _bg1 );
			addChild( _timeLineContainer );
			addChild( _controls );
			
			_controls.addEventListener( MouseEvent.CLICK, onClick );
			_controls.addEventListener( MouseEvent.MOUSE_MOVE, onMouseMove );
			_controls.addEventListener( MouseEvent.ROLL_OUT, onRollOut );
			_controls.addEventListener( MouseEvent.MOUSE_WHEEL, onMouseMove );
			_controls.addEventListener( Event.CHANGE, onControlParamChanged );
			
			addEventListener( DragEvent.DRAG_ENTER, onDragEnter );
		}
		
		/**
		 * Дорожки меняются местами 
		 */		
		private function swapTracks( index1 : int, index2 : int) : void
		{
			_seq.swapChannels( index1, index2 );
			timeline.swapTracks( index1, index2 );
			
			var lastTrack : int = _selectedTrack;
			
			if ( _selectedTrack == index1 )
			{
				_selectedTrack = index2;
			}
			else if ( _selectedTrack == index2 )
			{
			  _selectedTrack = index1;	
			}	
			
			if ( lastTrack != _selectedTrack )
			{
				timeline.selectTrack( _selectedTrack );
			}	
			else
			{
				timeline.updateSelection();
			}	
			
			_controls.swap( index1, index2 );	
		}
		
		/**
		 * Перемещает дорожку с указанным индексом, на другую позицию сдвигая соответствующим образом другие дорожки
		 * @param index
		 * 
		 */		
		private function moveTrackTo( fromIndex : int, toIndex : int ) : void
		{
			_seq.moveChannels( fromIndex, toIndex );
			timeline.moveTracks( fromIndex, toIndex );
			
			if ( _selectedTrack != -1 )
			{	
				var lastTrack : int = _selectedTrack;
				
				if ( _selectedTrack == fromIndex )
				{
					_selectedTrack = toIndex;
				}
				else  
				{
					var op      : Boolean = fromIndex < toIndex;
					var posFrom : int = op ? fromIndex : toIndex;
					var posTo   : int = op ? toIndex : fromIndex; 
					
					if ( ( _selectedTrack >= posFrom ) && ( _selectedTrack <= posTo ) )
					{	
						_selectedTrack += op ? -1 : 1;	
					}	
				}	
				
				if ( lastTrack != _selectedTrack )
				{
					timeline.selectTrack( _selectedTrack );
				}	
				else
				{
					timeline.updateSelection();
				}
			}
			
			_controls.moveTracks( fromIndex, toIndex );
		}	
		
		private function onDragEnter( e : DragEvent ) : void
		{
			if ( e.dragSource )
			{
				//Перемещение дорожек
				if ( e.dragSource.dataForFormat( 'trackControl' ) )
				{
					DragManager.acceptDragDrop( this );
					
					if ( ! _trackDragging )
					{
						timeline.dispatchEvent( new TracingEvent( TracingEvent.START_TRACING, false ) );
						stage.addEventListener( MouseEvent.MOUSE_MOVE, onMouseMoveThenTrackDragging );
						stage.addEventListener( MouseEvent.MOUSE_UP, onMouseUpThanTrackDragging );
						
						_emptyTrackPos = ControlContainer( e.dragSource.dataForFormat( 'trackControl' ) ).number;
						_startTrackPos = _lastTrackPos = _emptyTrackPos;
						_trackDragging = true;
					}	
					
					e.stopImmediatePropagation();
				}	
			}	
		}
		
		private function onMouseMoveThenTrackDragging( e : MouseEvent ) : void
		{
			var cPos : int = timeline.getHighlightedTrackNumber( e );
		    	
			if (  cPos != _lastTrackPos )
			{
				if ( cPos == -1 )
				{
					if ( _emptyTrackPos != _startTrackPos )
					{
						swapTracks( _emptyTrackPos, _startTrackPos );
						_emptyTrackPos = _startTrackPos;
					}
					
					DragManager.showFeedback( DragManager.NONE );
				}
				else
				{
					swapTracks( cPos, _emptyTrackPos );
					_emptyTrackPos = cPos;
					
					DragManager.showFeedback( DragManager.MOVE );
				}
				
				_lastTrackPos = cPos;
			}
		}
		
		private function onMouseUpThanTrackDragging( e : MouseEvent ) : void
		{
			stage.removeEventListener( MouseEvent.MOUSE_MOVE, onMouseMoveThenTrackDragging );
			stage.removeEventListener( MouseEvent.MOUSE_UP, onMouseUpThanTrackDragging );
			
			timeline.dispatchEvent( new TracingEvent( TracingEvent.STOP_TRACING ) );
			_trackDragging = false;
			
			if ( _emptyTrackPos != _startTrackPos )
			{
				var fromTrack : String = ( _startTrackPos + 1 ).toString();
				var toTrack   : String = ( _emptyTrackPos + 1 ).toString(); 
				
				History.add( new HistoryRecord( new HistoryOperation( this, moveTrackTo, _emptyTrackPos, _startTrackPos ),
					         new HistoryOperation( this, moveTrackTo, _startTrackPos, _emptyTrackPos ),
				    'Отменить перемещение дорожки ' + fromTrack, 'Поменять местами дорожку ' + fromTrack + ' и ' + toTrack
				) );
			}	
		}	
		
		private function onControlParamChanged( e : Event ) : void
		{
			timeline.updateSelection();
		}	
		
		private function onClick( e : MouseEvent ) : void
		{
			var track : int = timeline.getHighlightedTrackNumber( e );
			
			if ( track != -1 ) //Запрещаем снятие выделения	при клике
			{
				selectedTrack = track;	
			}		
		}	
		
		private function onMouseMove( e : MouseEvent ) : void
		{
			if ( ! _trackDragging )
			{
				var n : int = timeline.getHighlightedTrackNumber( e );
				
				timeline.highlightTrack( n );
				_controls.highlight( n );
			}	
		}
		
		private function onRollOut( e : MouseEvent ) : void
		{
			timeline.highlightTrack( -1 );
			_controls.highlight( -1 );
		}	
		
		private function onControlsMouseWheel( e : MouseEvent ) : void
		{
			_timeLineContainer.dispatchEvent( e );
		}	
		
		private function onTimelineInitialized( e : FlexEvent ) : void
		{
			timeline = _timeLineContainer.timeline;
			
			_timeLineContainer.removeEventListener( FlexEvent.INITIALIZE, onTimelineInitialized );
			_timeLineContainer.viewport.addEventListener( PropertyChangeEvent.PROPERTY_CHANGE, onTimeLinePropertyChange );
			
			timeline.scale = _scale;
			timeline.duration = _duration;
			
			timeline.addEventListener( MouseEvent.CLICK, onClick );
			timeline._markers.addEventListener( MarkerChangeEvent.PLAYHEAD_POSITION_CHANGED, onPlayheadPositionChanged );
			timeline._markers.addEventListener( MarkerEvent.PLAYHEAD_PRESS, onPlayHeadPress );
			timeline._markers.addEventListener( MarkerEvent.PLAYHEAD_RELEASE, onPlayHeadRelease );
			timeline._markers.addEventListener( MarkerEvent.DURATION_PRESS, onDurationPress );
			timeline._markers.addEventListener( MarkerEvent.DURATION_RELEASE, onDurationRelease );
			
			timeline.addEventListener( MarkerChangeEvent.LEFT_LOOP_BORDER_POSITION_CHANGED, onLeftLoopPositionChanged );
			timeline.addEventListener( MarkerChangeEvent.RIGHT_LOOP_BORDER_POSITION_CHANGED, onRightLoopPositionChanged );
		    
			//_timeLineContainer._timeLineContainer.addEventListener( MarkerChangeEvent.LOOP_CHANGED_ON, onLoopChanged );
			timeline.addEventListener( MarkerChangeEvent.LOOP_CHANGED_OFF, onLoopChanged );
			timeline.addEventListener( MarkerChangeEvent.START_LOOP_EDITING, onStartLoopEditing );
			timeline.addEventListener( MarkerChangeEvent.END_LOOP_EDITING, onEndLoopEditing );
			timeline.addEventListener( PropertyChangeEvent.PROPERTY_CHANGE, onTimelinePropertyChanged );
			
			//Изменения положения курсора трекером во время операции вырезания или вставки
			timeline.addEventListener( MarkerChangeEvent.PLAYHEAD_POSITION_CHANGED, onPlayheadPositionChangedByTracker );
			
			timeline.addEventListener( SelectionSampleEvent.CHANGE, onSelectionChange );
		}
		
		private function onPlayheadPositionChangedByTracker( e : MarkerChangeEvent ) : void
		{
			if ( ! _seq.playing )
			{
				_seq.position = e.pos;
				_positionChanged = true;
				_positionChangedBySeq = true;
				cScrollMode = TimeLineScrollMode.PLAYHEAD_CENTERED;
				
				invalidateProperties();
			}
		}
		
		private function onSelectionChange( e : SelectionSampleEvent ) : void
		{
			dispatchEvent( e );
		}
		
		private function onTimelinePropertyChanged( e : PropertyChangeEvent ) : void
		{	
			if ( e.property == 'scaleChanged' )
			{
				scale = Number( e.newValue );
				return;
			}
			
			if ( e.property == 'autoScroll' )
			{	
				autoScroll = Boolean( e.newValue );
				return;
			}
		}
		
		private function onStartLoopEditing( e : MarkerChangeEvent ) : void
		{
			_loopEditing = true;
		}
		
		private function onEndLoopEditing( e : MarkerChangeEvent ) : void
		{
			_loopEditing = false;
			_seq.startPosition = timeline.leftLoopPosition;
			_seq.endPosition   = timeline.rightLoopPosition;
			
			if ( _seq.loop != timeline.loopMarkers )
			{	
				_loop = true;
				_seq.loop = true;	
			}
		}	
		
		private function onLoopChanged( e : MarkerChangeEvent ) : void
		{
			/*if ( e.type == MarkerChangeEvent.LOOP_CHANGED_OFF )
			{*/
				_loop = false;
				_seq.loop = false;
				/*
				return;
			}	*/	
		}	
		
		private function onLeftLoopPositionChanged( e : MarkerChangeEvent ) : void
		{
			if ( ! _loopEditing )
			{
				_seq.startPosition = e.pos;
			}	
		}
		
		private function onRightLoopPositionChanged( e : MarkerChangeEvent ) : void
		{
			if ( ! _loopEditing )
			{
				_seq.endPosition = e.pos;	
			}
		}	
		
		/*duration changed history support*/
		
		private var _hDurationBefore : Number;
		
		private function historyChangeDuration( toDuration : Number, toPosition : Number, toStartPos : Number, toEndPos : Number ) : void
		{
			duration      = toDuration;
			position      = toPosition;
			startPosition = toStartPos;
			endPosition   = toEndPos;
		}
		
		/*duration changed history support*/
		
		private function onDurationPress( e : Event ) : void
		{
			_hDurationBefore = _duration;
			
			/*
			Устанавливаем границу изменения размера влево
			*/
			timeline._markers._durationHead.leftBorder = Math.max( Settings.DEFAULT_PROJECT_DURATION_IN_FRAMES, _seq.realDuration/*, _seq.position*/ );
			
			/*
			 При нажатии на маркер показываем максимально доступную длину
			*/
			timeDuration = Settings.MAX_PROJECT_DURATION;
		}
			
		private function onDurationRelease( e : Event ) : void
		{
			//Только если длина была изменена
			if ( _hDurationBefore != timeline._markers._durationHead.position )
			{
				/*
				При отпускании маркера распологаем маркер длины на ближайши целый такт
				*/
				var newDuration : Number = TimeConversion.roundNumSamplesToWholeBar( timeline._markers._durationHead.position, _bpm ); 
				
				if ( newDuration < timeline._markers._durationHead.leftBorder )
				{
					newDuration = TimeConversion.ceilNumSamplesToWholeBar( timeline._markers._durationHead.position, _bpm );
				}
				
				//Проверяем изменилось ли положение маркера после перетаскивания
				if ( newDuration != _hDurationBefore )
				{
					duration = newDuration;
					
					var op1 : HistoryOperation = new HistoryOperation( this, historyChangeDuration, _hDurationBefore, position, startPosition, endPosition ); 
					
					/*
					Если курсор воспроизведения оказывается за пределами длины микса, устанавливаем его на конец микса
					*/
					if ( position > newDuration )
					{
						position = newDuration;
					}
					
					//Проверяем границы петли маркеров зацикливания
					if ( endPosition > newDuration )
					{
						startPosition = Math.max( 0.0, startPosition - ( endPosition - newDuration ) );
						endPosition   = newDuration;
					}
					
					History.add( new HistoryRecord( op1, new HistoryOperation( this, historyChangeDuration, newDuration, position, startPosition, endPosition ),
						'Отменить изменение длинны микса', 'Повторить изменение длины микса' ) );
					
					return;
				}
			}
			
			duration = _hDurationBefore;
		}
		
		private function onPlayheadPositionChanged( e : MarkerChangeEvent ) : void
		{
		  _seq.position = e.pos;
		  dispatchEvent( new SequencerEvent( SequencerEvent.POSITION_CHANGED, e.pos ) );
		}
		
		private function onPlayHeadPress( e : Event ) : void
		{
		  _seq.captured = true;
		  _playHeadCaptured = true;	
		}
		
		private function onPlayHeadRelease( e : Event ) : void
		{
		  _seq.captured = false;
		  _playHeadCaptured = false;	
		}	
		
		private function onTimeLinePropertyChange( e : PropertyChangeEvent ) : void
		{
			if ( e.property == "verticalScrollPosition" )
			{
				_controls.verticalScrollPosition = Number( e.newValue );
			}	
		}	
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if ( _scale != timeline.scale )
			{
				timeline.scale = _scale;
			}
			
			if ( _duration != timeline.duration )
			{
				timeline.duration = _duration;
			}
			
			if ( _measureType != timeline.measureType )
			{
				timeline.measureType = _measureType;
			}
			
			if ( _viewType != timeline.viewType )
			{
				timeline.viewType = _viewType;
			}
			
			if ( _durationMarker != timeline._markers.durationMarker )
			{
				timeline._markers.durationMarker = _durationMarker;
			}
			
			if ( _bpm != timeline.bpm )
			{
				timeline.bpm = _bpm;
				_positionChanged = true;
				
				if ( _loop )
				{
					timeline.leftLoopPosition = _seq.startPosition;
					timeline.rightLoopPosition = _seq.endPosition;
				}	
			}
			
			if ( ! _loopEditing && ( _loop != timeline.loopMarkers ) )
			{
				if ( _loop )
				{
					_startPositionChanged = true;
					_endPositionChanged   = true;
				}	
				
				timeline.loopMarkers = _loop;
			}
			
			if ( _startPositionChanged )
			{
				timeline.leftLoopPosition = _seq.startPosition;
				_startPositionChanged = false;
			}
			
			if ( _endPositionChanged )
			{
				timeline.rightLoopPosition = _seq.endPosition;
				_endPositionChanged = false;
			}
			
			if ( _positionChanged && ! _playHeadCaptured )
			{
				timeline.position = _seq.position;
				
				if ( _positionChangedBySeq && autoScroll )
				{
					_timeLineContainer.scrollToPosition( _seq.position / _scale,  cScrollMode );
					cScrollMode = TimeLineScrollMode.SCROLL_ON_NEXT_VIEW;
				}
				
				_positionChangedBySeq = false;
				_positionChanged = false;
				
				dispatchEvent( new SequencerEvent( SequencerEvent.POSITION_CHANGED, _seq.position ) ); 
			}
			
			_timeLineContainer.validateProperties();
			timeline.validateProperties();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			
			var rullerHeight : Number = timeline.rullerHeight; 
			var hScrollBar   : Object = _timeLineContainer.skin.getChildByName( "horizontalScrollBar" );
			
			_bg.width = unscaledWidth;
			_bg.height = unscaledHeight;
			
			if ( timeline.numTracks == 0 )
			{
				_bg1.visible = false;
			}
			else
			{
				_bg1.visible = true;
				
				_bg1.width = unscaledWidth;
				_bg1.height = rullerHeight;
			}	
			
			_controls.setActualSize( _controls.getExplicitOrMeasuredWidth(), unscaledHeight - rullerHeight - hScrollBar.height );
			_controls.move( 0, rullerHeight );
			
			_timeLineContainer.setActualSize( unscaledWidth - _controls.width, unscaledHeight );
			_timeLineContainer.move( _controls.width, 0 );
		}
		
		/**
		 * Воспроизводить ли данные справа на лево
		 */	
		public function get inverse() : Boolean
		{	
			return _seq.inverse;
		}
		
		public function set inverse( value : Boolean ) : void
		{
			_seq.inverse = value;
		}
		
		public function get playing() : Boolean
		{
			return _seq.playing;
		}	
		
		/**
		 * Перемещает курсор воспроизведения к следующему такту 
		 * 
		 */		
		public function gotoNextBar() : void
		{
			var bars : Number = Math.floor( TimeConversion.numSamplesToBars( position + 0.00001, _bpm ) ) + 1;
			_positionChangedBySeq = true;
			position = TimeConversion.barsToNumSamples( bars, _bpm );
		}
		
		/**
		 * Перемещает курсор воспроизведения к предыдущему такту 
		 * 
		 */		
		public function gotoPrevBar() : void
		{
			var bars : Number = Math.ceil( TimeConversion.numSamplesToBars( position + 0.00001,  _bpm ) - 0.15 ) - 1;
			_positionChangedBySeq = true;
			position = TimeConversion.barsToNumSamples( bars, _bpm );
		}
		
		public function gotoStart() : void
		{
			_positionChangedBySeq = true;
			position = 0;
		}
		
		/**
		 * Запускает процесс воспроизведения 
		 * 
		 */		
		public function play() : void
		{
			_seq.play();	
		}
		
		/**
		 * Останавливает процесс воспроизведения 
		 * 
		 */		
		public function stop() : void
		{
			if ( _seq.recording ) 
			{
				stopRecording();
				return;
			}	
			
			_seq.stop();	
		}
		
		/**
		 * Возвращает индекс текущей выбранной дорожки 
		 * @return 
		 * 
		 */		
		public function get selectedTrack() : int
		{
			return _selectedTrack;
		}
		
		/**
		 * Устанавливает текущущую выбранную дорожку или снимает выделение при n == -1 
		 * @param n
		 * 
		 */		
		public function set selectedTrack( n : int ) : void
		{	
			timeline.selectTrack( n );
			_controls.select( n );
			_selectedTrack = n;
		}
		
		private var s    : BaseVisualSample;
		
		public function get recording() : Boolean
		{
			return _seq.recording;
		}	
		
		/**
		 * Запускает процесс записи 
		 */
		public function startRecording() : void
		{
			if ( _selectedTrack == -1 )
			{
				createTrack();
			    selectedTrack = numTracks - 1;
			}	
			
			s = timeline.createSampleForRecord( _seq.position, _selectedTrack );
			
			timeline.startRecordingTo( s );
			
			_seq.record( s.note.source );
		}
		
		/**
		 * Останавливает процесс записи 
		 * 
		 */		
		public function stopRecording() : void
		{	
			_seq.stop();
			timeline.stopRecordingFrom( s );
			
			s = null;
		}
		
		/**
		 * Очищает секвенсор для работы с "Нуля" 
		 * 
		 */		
		public function clearAll() : void
		{
			if ( playing ) stop();
			
			ignoreChanges = true;
			
			Clipboard.impl.clear();
			History.clear();
			selectedTrack = -1;
			
			timeline.clearAll();
			removeAllTracks();
			
			_seq.clear();
			
			loop = false;
			timeDuration = Settings.DEFAULT_PROJECT_DURATION;
			_seq.changeBPMTo( Settings.DEFAULT_PROJECT_BPM );
			
			scale = TimeLineParameters.DEFAULT_SCALE;
			System.gc(); //Включаем очистку мусора Garbage Collector
			ignoreChanges = false;

			dispatchEvent( new SequencerEvent( SequencerEvent.CLEAR ) );
		}	
				
		public function get showDragAndDropTip() : Boolean
		{
			return timeline.showDragAndDropTip;
		}
		
		public function set showDragAndDropTip( value : Boolean ) : void
		{
			timeline.showDragAndDropTip = value;
		}
	}
}