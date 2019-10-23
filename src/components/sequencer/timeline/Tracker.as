package components.sequencer.timeline
{
	import com.audioengine.core.AudioData;
	import com.audioengine.core.DummyAudioData;
	import com.audioengine.core.IAudioData;
	import com.audioengine.core.TimeConversion;
	import com.audioengine.sequencer.AudioLoop;
	import com.audioengine.sequencer.Note;
	import com.audioengine.sources.IAudioDataSource;
	import com.audioengine.sources.Routines;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getQualifiedClassName;
	import flash.utils.setTimeout;
	
	import mx.core.FlexGlobals;
	import mx.core.mx_internal;
	import mx.effects.Tween;
	import mx.events.DragEvent;
	import mx.events.MenuEvent;
	import mx.managers.CursorManager;
	import mx.managers.DragManager;
	import mx.managers.ToolTipManager;
	import mx.managers.history.History;
	import mx.managers.history.HistoryOperation;
	import mx.managers.history.HistoryRecord;
	import mx.styles.StyleManager;
	
	import classes.BaseDescription;
	import classes.PaletteSample;
	import classes.SamplesPalette;
	import classes.Sequencer;
	import classes.SequencerImplementation;
	import classes.events.CreateTrackEvent;
	
	import components.Base;
	import components.managers.HintManager;
	import components.menu.Menu;
	import components.sequencer.clipboard.Clipboard;
	import components.sequencer.clipboard.SampleClipboardRecord;
	import components.sequencer.timeline.events.MarkerChangeEvent;
	import components.sequencer.timeline.events.SelectionSampleEvent;
	import components.sequencer.timeline.events.TracingEvent;
	import components.sequencer.timeline.events.TrackerEvent;
	import components.sequencer.timeline.visual_sample.ActionButton;
	import components.sequencer.timeline.visual_sample.BaseVisualSample;
	import components.sequencer.timeline.visual_sample.DragDropCursor;
	import components.sequencer.timeline.visual_sample.ResizeLeftButton;
	import components.sequencer.timeline.visual_sample.ResizeRightButton;
	import components.sequencer.timeline.visual_sample.VisualSample;

	public class Tracker extends BaseTracker
	{
		/**
		 * Масштаб, меньше которого отключается привязка к сетке и включается, только залипание 
		 */		
		private static const FREE_MOVING_SCALE : Number = 500.0;
		
		/**
		 * Время обновления данных после автоматического создания дорожек 
		 */		
		private static const UPDATE_TIME : Number = 150.0;
		
		/**
		 * Классы курсоров 
		 */		
		private var _currentCursor : Class;
		private var copyCursor : Class;
		private var rejectCursor : Class;
		
		/**
		 * Область прилипания относительно сетки 
		 */		
		private const _stickingArea : int = 0.01 * AudioData.RATE;
		
		private var _sliping      : Boolean;
		private const _slipingCount : int = 6.0;
		private var _slipingInc   : int = 0;
		
		/**
		 * Привязывать ли семплы к сетке при перетаскивании 
		 */		
		private var _stickToGrid : Boolean = true;
		
		/**
		 * Залипать при прохождении границ петли 
		 */		
		private var _stickToLoopsBorder : Boolean = true;
		
		/**
		 * Приклеваться к границам других семплов при перетаскивании 
		 */		
		private var _stickToOtherLoops : Boolean = true;
		
		/**
		 * Текущий семл с которым в настоящий момент происходит перетаскивание/растяжение 
		 */		
		private var _activeSample : BaseVisualSample;
		/**
		 * Группа семплов с которыми сейчас происходит операция перетаскивания\копирования 
		 */		
		private var _activeSamples : Vector.<BaseVisualSample>;
		
		/**
		 * Смещение для перетаскивания 
		 */		
		private var _dragOffset : Point;
		
		/**
		 * Текущее выполняемое действие 
		 */
		private static const UNDO_CLONING   : int = -2;
		private static const UNDO_DRAGGING  : int = -1;
		private static const NONE           : int = 0;
		private static const START_DRAGGING : int = 1;
		private static const DRAGGING       : int = 2;
		private static const CLONING        : int = 3;
		private static const RESIZE_LEFT    : int = 4;
		private static const RESIZE_RIGHT   : int = 5;
		private static const DRAG_DROP      : int = 6;
		
		private var _currentAction : int = NONE;
		
		/**
		 * Список треков принадлежащих определенной дорожке (кеширование. оптимизация) 
		 */		
		private var _firstSamples      : Vector.<BaseVisualSample>;
		private var _selectedSamples   : Vector.<BaseVisualSample> = new Vector.<BaseVisualSample>();
		private var _lastPermanentSelection : Boolean; //Указывает что предыдущий семпл(ы) был выбран средством массового выбора
		private var _lastSampleSelected : Boolean;
		
		/**
		 * Буфер для хранения дополнительной истории операций 
		 */		
		private var historyOp : HistoryOperation;
		
		/**
		 * Список данных семплов до начала перетаскивания, для отмены, в случае неудачи 
		 */		
		private var _initialPositions  : Vector.<InitialSamplePosition>;
		private var _groupLeft         : BaseVisualSample;
		private var _groupLeftIndex    : int;
		
		private var _groupRight        : BaseVisualSample;
		private var _groupRightIndex   : int;
		
		private var _groupTop          : BaseVisualSample;
		private var _groupBottom       : BaseVisualSample;
		private var _draggingStatus    : int; //Текущий статус перетаскивания группы ( можно/нельзя переместить в выбранную позицию )
		
		private var _startNumTracks    : int; //Здесь запоминается количество дорожек перед операцией перетаскивания
		private var _virtualNumTracks  : int; //Количество дорожек доступных во время операции перетаскивания
		                                      //_numTracks + dTrackNumber
		
		private var _numTracksWillBeCreated : int; //Количество дорожек которые необходимо создать, чтобы после окончания
		                                             //операции перетаскивания
		
		/**
		 * Сюда клонируются семплы на время операции клонирования 
		 */		
		private var _clonedSamples     : Vector.<BaseVisualSample>;
		
		/**
		 * Смещение инициирующее процесс перетаскивания
		 */
		private static const START_DRAGGING_OFFSET : Number = 3.0;
		/**
		 * Событие инициировавшее процесс перетаскивания 
		 */
		private var _dragInitiatorEvent : MouseEvent;
		
		/**
		 * Перечисление возможных статусов перетаскивания 
		 */
		private static const DRAGGING_STATUS_YES : int = 0;
		private static const DRAGGING_STATUS_NO  : int = 1;
		
		//анимационный tween
		private var _tween : Tween;
		//Время возвращения семплов обратно
		private var _draggingUndoTime  : Number = 250.0;
		
		/**
		 * Список номеров выбранных дорожек 
		 */
		private const _selectedTracks : Vector.<int> = new Vector.<int>();
		
		/**
		 * Кнопка вызова меню действий над семплом 
		 */		
		private var _actionButton : ActionButton;
		
		/**
		 * Кнопка растяжения сепла вправо 
		 */		
		private var _resizeToRightButton : ResizeRightButton;
		
		/**
		 * Кнопка растяжения семпла влево 
		 */		
		private var _resizeToLeftButton  : ResizeLeftButton;
		
		/**
		 * Указатель на пустышку DragManager 
		 */		
		private var _dragImage : DisplayObject;
		
		
		private var _seq : classes.SequencerImplementation;
		private var _palette : SamplesPalette;
		
		private var _currentMenu : Menu;
		
		public function Tracker()
		{
			super();
			
			addEventListener( TracingEvent.START_MOVING, onStartMoving );
			addEventListener( TracingEvent.STOP_MOVING, onStopMoving );
			
			copyCursor   = StyleManager.getStyleManager( null ).getStyleDeclaration( 'mx.managers.DragManager' ).getStyle( 'copyCursor' );
			rejectCursor = StyleManager.getStyleManager( null ).getStyleDeclaration( 'mx.managers.DragManager' ).getStyle( 'rejectCursor' );
			
			_seq     = classes.Sequencer.impl;
			_palette = _seq.palette; 
			
			_actionButton = new ActionButton();
			_actionButton.visible = false;
			_actionButton.addEventListener( MouseEvent.ROLL_OVER, onVisualSampleActionButtonRollOver );
			_actionButton.addEventListener( MouseEvent.ROLL_OUT, onVisualSampleActionButtonRollOut );
			_actionButton.addEventListener( MouseEvent.CLICK, onVisualSampleActionButtonClick );
			
			_resizeToLeftButton = new ResizeLeftButton();
			_resizeToLeftButton.visible = false;
			
			_resizeToRightButton = new ResizeRightButton();
			_resizeToRightButton.visible = false;
			
			_resizeToLeftButton.touch();
			_resizeToRightButton.touch();
			_actionButton.touch();
		}
		
		public function get selectedSamples() : Vector.<BaseVisualSample>
		{
			return _selectedSamples;
		}
		
		public function onStartMoving( e : TracingEvent ) : void
		{
			_stickToGrid = false;
			_stickToLoopsBorder = false;
			_stickToOtherLoops = false;
		}
		
		public function onStopMoving( e : TracingEvent ) : void
		{
			_stickToGrid = true;
			_stickToLoopsBorder = true;
			_stickToOtherLoops = true;
		}	
		
		public function onDragEnter( e : DragEvent ) : void
		{
		 _activeSample = null;
		}
		
		private function dragEnterHandler( e : DragEvent, trackNumber : int ) : void
		{
			if ( ! _activeSample )
			{
				var d : BaseDescription = e.dragSource.dataForFormat( 'sample' ) as BaseDescription;
				
				if ( d )
				{
					_activeSample = createDropCursor( trackNumber, d );
					
					var _dummy : DisplayObject = DisplayObject( e.dragSource.dataForFormat( 'dragImage' ) );
					
					if ( _dummy )
					{
						_dragImage = _dummy;
						_dragImage.alpha = 0.5;
					}
					
					initSampleAction( MouseEvent( e ), _activeSample, DRAG_DROP );
					onStageMouseMove( MouseEvent( e ) );
				}
			}
		}	
		
		public function onDragOver( e : DragEvent ) : void
		{
			var trackNumber : int = cursorPositionToTrackNumber( globalToLocal( new Point( e.stageX, e.stageY ) ).y );
			
			if ( trackNumber == -1 )
			{
			   DragManager.showFeedback( DragManager.NONE );
			   onDragExit( null );	  
			}
			else
			{
				dragEnterHandler( e, trackNumber );	
			}
		}	
		
		public function onDragDrop( e : DragEvent ) : void
		{
			var s : VisualSample;
			var sd : BaseDescription = e.dragSource.dataForFormat( 'sample' ) as BaseDescription;
			
			//Разместить семпл на выбранной дорожке
			if ( _activeSample )
			{
				_activeSample.description = null;
				
				if ( DragManager.getFeedback() == DragManager.COPY )
				{
					s = new VisualSample();
					s.description  = sd;
					s.position     = _activeSample.position;
					/*s.note         = new Note( s.position, new AudioLoop( new DummyAudioData( d.id, d.duration, d.bpm ) ) );
					s.note.source.locked = true;*/
					
					s.duration     =  s.loopDuration = calcSampleLength( sd );
					
					//Семп расположен на существующей
					if ( _activeSample.trackNumber < _numTracks )
					{
						s.trackNumber  = _activeSample.trackNumber;
						addSample( s );
						
						/*add to history*/
						History.add( new HistoryRecord( new HistoryOperation( this, removeSamplesByNames, Vector.<String>( [ s.name ] ) ),
							                            new HistoryOperation( this, addSamplesByDescriptions, serializeSamples( Vector.<BaseVisualSample>( [ s ] ) ) ), 'Удалить сэмпл ' + sd.name, 'Добавить сэмпл ' + sd.name )                                         
							       );
					
					}	
					else //Семпл добавляется путем добавления на не существующую дорожку
					{
						s.trackNumber = _numTracks;
						
						History.startCatching();
						
						//Создать дорожку
						_seq.sendCommand( new CreateTrackEvent( CreateTrackEvent.CREATE_TRACK, _numTracks, 1 ) );
						
						addSample( s );
						
						/*add to history*/
						History.recordHook.add( null, new HistoryOperation( this, addSamplesByDescriptions, serializeSamples( Vector.<BaseVisualSample>( [ s ] ) ) ) );
						History.recordHook.forwardName = 'Добавить сэмпл ' + sd.name;
						History.recordHook.backName    = 'Удалить сэмпл ' + sd.name;
						History.stopCatching();
					}
				}
				
				onDragExit( null );
			}
			/*
			else //Создать дорожку и разместить на ней семпл( Сейчас этот вариант не рабочий !!! )
			{
				if ( DragManager.getFeedback() == DragManager.COPY )
				{
					s = new VisualSample();
					s.trackNumber = _numTracks;
					s.description = d;
					s.duration    = TimeConversion.scaleDuration( d.duration, d.bpm, _bpm );
					s.loopDuration= s.duration;
					//Создать дорожку
					_seq.sendCommand( new CreateTrackEvent( CreateTrackEvent.CREATE_TRACK, _numTracks ) );
					//Добавляем семпл на дорожку
					setTimeout( addSampleAfterDelay, 150.0, s, true );	
				}
			}
			*/
		}
		
		public function onDragExit( e : DragEvent ) : void
		{
			if ( _activeSample )
			{
				onStageMouseUp( null );
					
				if ( _dragImage )
				{
					_dragImage.alpha = 1;
					_dragImage = null;
				}	
				
				destroyDropCursor( _activeSample );
				_activeSample = null;
			}
		}	
		
		/**
		 * Вычисляет длину сэмпла в рабочей области 
		 * @param sd
		 * 
		 */		
		private function calcSampleLength( sd : BaseDescription ) : Number
		{
			return sd.loop ? TimeConversion.calcLoopDuration( sd.duration, sd.bpm, _bpm ) : sd.duration;
		}
		
		private function createDropCursor( trackNumber : int, sd : BaseDescription ) : BaseVisualSample
		{
			var s : BaseVisualSample = BaseVisualSample( new DragDropCursor() );
		
			s.contentHeight = _trackHeight;
			s.scale = _scale;
			s.duration = calcSampleLength( sd );
			s.trackNumber = trackNumber;
			s.description = sd;
			s.touch();
			
			addChild( s );
			
			return s;
		}
		
		private function destroyDropCursor( s : BaseVisualSample) : void
		{
			removeChild( s );
			s = null;
		}
		
		/**
		 * Сдвигает номер трека всех семплов на offset, треков начиная c start трека
		 * @param offset
		 * 
		 */		
		private function shiftSamplesTrackNumber( start : int, offset : int = 1 ) : void
		{
			var i : int = 0;
			
			while( i < numChildren )
			{
				var s : BaseVisualSample = getChildAt( i ) as BaseVisualSample;
				
				if ( s )
				{
					if ( s.trackNumber >= start )
					{
						s.trackNumber += offset;
					}	
				}	
				
				i ++;
			}	
		}
		
		public function moveTracks( from : int, to : int ) : void
		{
			//Перемещаем семплы на указанной дорожке
			var i : int = 0;
			
			//Сдвигаем номера всех дорожек вверх или вниз
			var op      : Boolean = from < to;
			var posFrom : int = op ? from : to; 
			var posTo   : int = op ? to : from;
			var inc     : int = op ? -1 : 1;
			
			while( i < numChildren )
			{
				var s : BaseVisualSample = getChildAt( i ) as BaseVisualSample;
				
				if ( s )
				{
					if ( s.trackNumber == from )
					{
						s.trackNumber = to;
					}
					else
					 if ( ( s.trackNumber >= posFrom ) && ( s.trackNumber <= posTo ) )
					 {
						 s.trackNumber += inc;
					 }	 
					
				}
				
				i ++;
			}	
			
			_needUpdate = true;
			touch();  
		}	
		
		/**
		 * Меняет местами две дорожки с указанными индексами 
		 * @param index1
		 * @param index2
		 * 
		 */		
		public function swapTracks( index1 : int, index2 : int ) : void
		{
			var i : int = 0;
			
			while( i < numChildren )
			{
				var s : BaseVisualSample = getChildAt( i ) as BaseVisualSample;
				
				if ( s )
				{
					if ( s.trackNumber == index1 )
					{
						s.trackNumber = index2;
					}
					else if ( s.trackNumber == index2 )
					{
						s.trackNumber = index1;
					}	
				}	
				
				i ++;
			}
			
			_needUpdate = true;
			touch();
		}	
		
		/**
		 * Создает новый трек 
		 * @param index - позиция в которой вставить трек относительно других треков
		 * по умолчанию -1 - создать новый трек в самом конце
		 * 
		 */		
		public function createTrackAt( index : int ) : void
		{
			//Если на треках ниже ввновь создаваемого есть семплы, то перекидываем их на +1 трек
			if ( index < _numTracks )
			{
				shiftSamplesTrackNumber( index );	
			}
			
	        _numTracks ++;
			
			_needUpdate = true;
			_needMeasure = true;
			
			touch();
		}
		
		public function removeSamplesOnTrack( index : int ) : void
		{	
		  	var samples : Vector.<BaseVisualSample> = getVisualSamples( index );
			var i       : int = 0;
			
			if ( samples )
			{
				while( i < samples.length )
				{
					removeSample( samples[ i ] );
					i ++;
				}	
			}	
		}
		
		/**
		 * Удаляет трек с указанным индексом 
		 * @param index - индекс трека который необходимо удалить
		 * 
		 */		
		public function removeTrackAt( index : int ) : void
		{
			//Удаляем семплы на дорожке
			removeSamplesOnTrack( index );
			
			//Сдвиг семплов на дорожку выше
			if ( index < _numTracks )
			{
			  shiftSamplesTrackNumber( index, -1 );
			}	
					
			_numTracks --;
			
			_needUpdate = true;
			_needMeasure = true;
			
			touch();
		}	
	
		override protected function update():void
		{		
			super.update();
			
			if ( _bpmChanged )
			{
				orderAfterChangeBPM();
				_bpmChanged = false;
			}	
			else
			{
				orderSamples();
			}	
			
			orderVisibleSamples();
		}
		
		private function removeSamplesByNames( names : Vector.<String> ) : void
		{
			var samples : Vector.<BaseVisualSample> = sampleNamesToSampleList( names );	
			
			for each( var s : BaseVisualSample in samples )
			{	
				removeSample( s );
			}
		}	
		
		public function removeSample( s : BaseVisualSample ) : void
		{
			_numSamples --;
			
			if ( s.note )
			{
				if ( _seq.noteExistsOnChannel( s.note, s.trackNumber ) )
				{
					_seq.removeNoteFrom( s.note, s.trackNumber );	
				}
			}	
			
			s.removeEventListener( MouseEvent.MOUSE_UP, onSampleMouseUp );
			s.removeEventListener( MouseEvent.MOUSE_DOWN, onSampleMouseDown );
			s.removeEventListener( MouseEvent.ROLL_OVER, onVisualSampleRollOver );
			s.removeEventListener( MouseEvent.ROLL_OUT, onVisualSampleRollOut );
			s.removeEventListener( 'indicatorClick', onVisualSampleActionButtonClick );
			s.removeEventListener( 'errorButtonClick', onErrorButtonClick );
			
			var vs : VisualSample = s as VisualSample;
			
			if ( vs )
			{
				if ( vs.selected )
				{
					removeFromSelected( vs );
				}
				
				removeElements();
				vs.detachFromWave();
				
				if ( vs.selected )
				{
					
				}
			}	
		
			removeChild( s );
		}	
		
		/**
		 * Добавляет семпл на указанную дорожку и позицию по его описанию 
		 * @param description
		 * @param position
		 * @param trackNumber
		 * 
		 */		
		public function addSamplesByDescriptions( list : Vector.<SampleClipboardRecord> ) : void
		{
			var i : int = 0;
			var sample  : BaseVisualSample;
			var samples : Vector.<BaseVisualSample> = deserializeSamples( list ); 
			
			//Коректируем положение группы семплов с учетом указанной позиции
			while( i < samples.length )
			{
				sample = samples [ i ];
				
				/*if ( sample.note )
				{
					_seq.addNoteTo( sample.note, sample.trackNumber );
					addSample( sample, false, false );
				}	
				else
				{*/
					addSample( sample, true, false );
				//}	
				
				
				i ++;
			}	
		}
		
		/**
		 * Текущий индентификатор записи нового семпла 
		 */		
		private var record_id : int = 0;
		
		/**
		 * Создает "Пустой семпл" - для записи
		 * @param pos
		 * @param trackNumber
		 * @return 
		 * 
		 */		
		public function createSampleForRecord( pos : Number, trackNumber : int ) : BaseVisualSample
		{
			/*var id : String = 'Record ' + ( record_id + 1 ).toString(); 
			
			var data : IAudioData = new AudioData( id );
			
			var sd : SampleDescription = new SampleDescription( id, null, id, 0.0, _bpm, null, null, 'record', 'acapella', false );
			var sp : PaletteSample = new PaletteSample( sd, data );
			
			_seq.palette.addSample( sp );
			_seq.palette.waves.createW( sd.id, data );
			
			var s : VisualSample = new VisualSample();
			    s.description  = sd;
			    s.position     = pos;
			    s.duration     = sd.duration; 
			    s.loopDuration = sd.duration;
				s.trackNumber  = trackNumber;
				
				s.note = new Note( pos, data );
				_seq.addNoteTo( s.note, trackNumber );
				s.attachToWave( true, false, false );
				
			addSample( s, false );
			addActionToHistoryAddSamples( Vector.<BaseVisualSample>( [ s ] ) ); 
			
			record_id ++;
			
			return s;*/
			return null;
		}
		
		/**
		 * Список семплов в режиме автообновления 
		 */		
		private var autoUpdatingSamples : Vector.<BaseVisualSample> = new Vector.<BaseVisualSample>();
		
		private function getAutoUpdatingSampleIndexFromAudioSource( a : IAudioData ) : int
		{
			var i : int = 0;
			
			while( i < autoUpdatingSamples.length )
			{
				var s : BaseVisualSample = autoUpdatingSamples[ i ];
				
				if ( s.note.source == a )
				{
					return i;
				}	
				
				i ++;
			}
			
			return -1;
		}	
		
		/**
		 * Запускает механизм автоматического обновления семпла при изменении данных источника 
		 * @param s
		 * 
		 */		
		public function startRecordingTo( s : BaseVisualSample ) : void
		{
			s.mouseEnabled  = false;
			s.mouseChildren = false;
			s.note.source.addEventListener( Event.CHANGE, onAudioSourceChange );
			autoUpdatingSamples.push( s );
		}
		
		/**
		 * Останавливает механизм автоматического обновления семпла при изменении данных источника 
		 * @param s
		 * 
		 */		
	    public function stopRecordingFrom( s : BaseVisualSample ) : void
		{	
			var index : int = getAutoUpdatingSampleIndexFromAudioSource( s.note.source );
			
			s.note.source.removeEventListener( Event.CHANGE, onAudioSourceChange );
			
			autoUpdatingSamples.splice( index, 1 );
			
			//Обновляем описание
			s.description.duration = s.note.source.length;
			
			//Апгрейдим источник семпла до AudioLoop
			var a : IAudioData = s.note.source;
			_seq.removeNoteFrom( s.note, s.trackNumber );
			s.note = new Note( s.position, new AudioLoop( a, _bpm, false ) );
			_seq.addNoteTo( s.note, s.trackNumber );
		
			s.mouseEnabled  = true;
			s.mouseChildren = true;
		}
		
		/**
		 * Измененение данных источника 
		 * @param e
		 * 
		 */		
		private function onAudioSourceChange( e : Event ) : void
		{
			var s : VisualSample = VisualSample( autoUpdatingSamples[ getAutoUpdatingSampleIndexFromAudioSource( IAudioData( e.target ) ) ] );
			    s.loopDuration = s.duration = s.note.source.length;
			    s.visible = true;
				s.updateWave();	
			    s.touch();
			
			orderVisualSampleElements( s, true );
		}	
		
		private function configureSample( s : BaseVisualSample, setName : Boolean = true ) : void
		{
			s.contentHeight = _trackHeight;
			s.scale         = _scale;
			
			s.addEventListener( MouseEvent.MOUSE_UP, onSampleMouseUp );
			s.addEventListener( MouseEvent.MOUSE_DOWN, onSampleMouseDown );
			s.addEventListener( MouseEvent.ROLL_OVER, onVisualSampleRollOver );
			s.addEventListener( MouseEvent.ROLL_OUT, onVisualSampleRollOut );
			s.addEventListener( 'indicatorClick', onVisualSampleActionButtonClick );
			s.addEventListener( 'errorButtonClick', onErrorButtonClick );
			
			if ( setName )
			{
				s.name = getUnicalSampleName( s );
			}	
			
			orderSample( s );
			addChild( s );
			
			//trace( 'newName=' + s.name );
		}	
		
		public function get numSamples() : int
		{
			return _numSamples;
		}
		
		private var _numSamples : int;
		
		public function addSample( s : BaseVisualSample, addNote : Boolean = true, setName : Boolean = true ) : void
		{
			_numSamples ++;
			
			configureSample( s, setName );
			
			var vs : VisualSample = s as VisualSample;
		
			if ( vs )
			{
				if ( addNote )
				{
					if ( ! s.note )
					{
						var paletteSample : PaletteSample = _palette.add( s.description );
						
						if ( paletteSample.ready )
						{
							s.note = new Note( s.position, new AudioLoop( paletteSample.source, _bpm, s.description.loop ) );
							
							if ( ! vs.waveIsAttached )
							{
								vs.attachToWave();	
							}
						}
						else
						{
							//Если для этого загрузчика уже установлены слушатели, то не ставим их
							if ( getSampleById( paletteSample.loader.id ).length == 1 )
							{
								setLoaderListeners( paletteSample.loader );
							}	
							
							//Устанавливаем пустую ноту на время загрузки
							s.note = new Note( s.position, new AudioLoop( new DummyAudioData( s.description.id, Routines.ceilLength( s.description.duration, s.description.bpm ), s.description.bpm, s.description.loop ) ) );	
							
							vs.loading = true;
							
							//Поддержка истории добавления/удаления сэмпла из палитры
							History.add( new HistoryRecord( new HistoryOperation( _palette, _palette.removeSample, paletteSample ), null ) );
						}
					}	
					
					_seq.addNoteTo( s.note, s.trackNumber );
				}		
			}
			
			afterAction( s );
		}
		
		private function setLoaderListeners( loader : IAudioDataSource ) : void
		{
			loader.addEventListener( Event.COMPLETE, onSampleLoaded );
			loader.addEventListener( ErrorEvent.ERROR, onSampleError );
			loader.addEventListener( IOErrorEvent.IO_ERROR, onSampleError );
			loader.addEventListener( ProgressEvent.PROGRESS, onSampleProgress );	
		}
		
		private function removeLoaderListeners( loader : IAudioDataSource ) : void
		{
			loader.removeEventListener( Event.COMPLETE, onSampleLoaded );
			loader.removeEventListener( ErrorEvent.ERROR, onSampleError );
			loader.removeEventListener( IOErrorEvent.IO_ERROR, onSampleError );
			loader.removeEventListener( ProgressEvent.PROGRESS, onSampleProgress );	
		}
		
		/**
		 * Возвращает семплов с указанным id, по его уникальному идентификатору или null если такого не найдено
		 * В результат не включаются сэмплы в состоянии ошибки!!! 
		 * @param id
		 * @return 
		 * 
		 */		
		private function getSampleById( id : String, excludeError : Boolean = true  ) : Vector.<BaseVisualSample>
		{
		  var result : Vector.<BaseVisualSample> = new Vector.<BaseVisualSample>();
		  var i : int = 0;
		  
		  while( i < numChildren )
		  {
			  var s : VisualSample = getChildAt( i ) as VisualSample;
			  
			  if ( s && s.description && ( s.description.id == id ) )
			  {
				 if ( excludeError )
				 {
					 if ( ! s.error )
					 {
						 result.push( s );  
					 }
				 }
				 else 
				 {
					 result.push( s ); 
				 }
			  }
			  
			  i ++;
		  }
		   
		  return ( result.length == 0 ) ? null : result;
		}	
		
		private function onSampleError( e : ErrorEvent ) : void
		{
			var loader : IAudioDataSource = IAudioDataSource( e.currentTarget );
			removeLoaderListeners( loader );
			
			var samples : Vector.<BaseVisualSample> = getSampleById( loader.id, false );
			
			if ( samples )
			{
				showError( 'Не могу найти файл "' + samples[ 0 ].description.name + '"' );
				
				var vs : VisualSample;
				
				for each( var s : BaseVisualSample in samples )
				{
					vs = VisualSample( s );
					
					if ( vs.error ) //Не удаляем те которые были до этого в состоянии ошибки
					{
						vs.loading = false;
						vs.touch();
						orderVisualSampleElements( vs );
					}
					else //Удаляем только что дропнутые файлы
					{
						removeSample( s );	
					}
				}
			}
		}
		
		private function onSampleProgress( e : ProgressEvent ) : void
		{
			var loader : IAudioDataSource = IAudioDataSource( e.currentTarget );
			
			var samples : Vector.<BaseVisualSample> = getSampleById( loader.id, false );
			
			if ( samples )
			{
				var i : int = 0;
				var vs : VisualSample;
				
				while( i < samples.length )
				{
					vs = samples[ i ] as VisualSample;
					
					if ( ! vs.loading )
					{
						vs.loading = true;
						vs.touch();
						orderVisualSampleElements( vs );
					}
					
					vs.setProgress( e.bytesLoaded, e.bytesTotal );
					
					i ++;
				}
			}	
		}	
		
		private function onSampleLoaded( e : Event ) : void
		{
			var loader : IAudioDataSource = IAudioDataSource( e.currentTarget );
			removeLoaderListeners( loader );
			
			var samples : Vector.<BaseVisualSample> = getSampleById( loader.id, false );
			var i : int = 0;
			
			if ( samples )
			{	
				while( i < samples.length )
				{
					var vs : VisualSample = samples[ i ] as VisualSample;
					
					if ( vs )
					{
						//Синхронизируем параметры пустышки с семплом
						var dummy : AudioLoop = AudioLoop( vs.note.source );
						var loop  : AudioLoop = new AudioLoop( loader.source, _bpm, dummy.loop );
						
						loop.inverted = dummy.inverted;
						loop.length   = dummy.length;
						loop.offset   = dummy.offset; 
						
						var channelExists : Boolean = _seq.channelExists( vs.trackNumber );
						var noteExists    : Boolean = channelExists ? _seq.noteExistsOnChannel( vs.note, vs.trackNumber ) : false;
						
						//Удаляем ранее добавленную "Пустую ноту"
						if ( channelExists && noteExists )
						{
							_seq.removeNoteFrom( vs.note, vs.trackNumber, false );
						}	
						
						vs.note = new Note( vs.position, loop );
						
						if ( channelExists )
						{
							_seq.addNoteTo( vs.note, vs.trackNumber, false );	
						}
						
						vs.error = false;
						vs.loading = false;
						
						vs.attachToWave( ! loop.loop, loop.inverted );
						
						//Обновляем на всякий случай длину ( Если длина была определена не точно до этого )
						//afterChangeBPM( vs );
						
						vs.touch();
						
						if ( vs.hovered )
						{
							attachElementsTo( vs );
						}
						
						orderVisualSampleElements( vs, ! vs.hovered );
					}	
					
					i ++;
				}	
			}	
		}	
		
		private function nextSlipping() : void
		{
			_slipingInc ++;
			if ( _slipingInc > _slipingCount )
			{
				_sliping = false;
				_slipingInc = 0;
			}
		}
		
		/**
		 * Определяет ключевые семплы в группе выделенных семплов и запоминает текущее положение 
		 * + определяет количество доступных виртуальных дорожек
		 */		
		private function saveInitialPosition() : void
		{
			var i : int = 0;
			
			_initialPositions = new Vector.<InitialSamplePosition>();
			
			while( i < _activeSamples.length )
			{
				var s : BaseVisualSample = _activeSamples[ i ];
				
				if ( i == 0 )
				{
					_groupLeft     = s;
					_groupRight    = s;
					_groupTop      = s;
					_groupBottom   = s;
					
					_groupLeftIndex = 0;
					_groupRightIndex = 0;
				}
				else
				{
					if ( s.position < _groupLeft.position )
					{
						_groupLeft = s;
						_groupLeftIndex = i;
					}
					
					if ( s.position + s.duration > _groupRight.position + _groupRight.duration )
					{
						_groupRight = s;
						_groupRightIndex = i;
					}
					
					if ( s.trackNumber < _groupTop.trackNumber )
					{
						_groupTop = s;
					}
					
					if ( s.trackNumber > _groupBottom.trackNumber )
					{
						_groupBottom = s;
					}	
				}	
				
				//Делаем выделенные семплы выше всех
				setChildIndex( s, numChildren - 1 );
				
				_initialPositions.push( new InitialSamplePosition( s.position, s.trackNumber, getVisualSamples( s.trackNumber ) ) ); 
				
				i ++;
			}
			
			//Определяем количество доступных виртуальных дорожек
			_virtualNumTracks = Math.min( _numTracks + ( _groupBottom.trackNumber - _groupTop.trackNumber ) + 1,
				                           TimeLineParameters.MAX_NUM_TRACKS );
			_startNumTracks = _numTracks;
			_numTracksWillBeCreated = 0;
		}
		
		/**
		 * Создает копию выделенных семплов
		 * И возвращает копию _activeSample 
		 * 
		 */		
		private function  cloneSelected() : BaseVisualSample
		{
			var i : int = 0;
			var result : BaseVisualSample;
			
			_clonedSamples = new Vector.<BaseVisualSample>();
			
			while( i < _selectedSamples.length )
			{
				var src : BaseVisualSample = _selectedSamples[ i ];
				var dst : BaseVisualSample = src.clone();
				addSample( dst, false );
				
				_clonedSamples.push( dst );
				
				if ( src == _activeSample )
				{
					result = dst;
				}	
				
				i ++;
			}
			
			return result;
		}	
		
		private function initSampleAction( event : MouseEvent, currentTarget : Object, action : int ) : void
		{
			var s : BaseVisualSample = BaseVisualSample( currentTarget );
			var vs : VisualSample = s as VisualSample;
			
			_activeSample = s;
			
			if ( action != START_DRAGGING )
			{
				_firstSamples = getVisualSamples( s.trackNumber );
			}	
			
			stage.addEventListener( MouseEvent.MOUSE_UP, onStageMouseUp/*, true*/ );
			stage.addEventListener( MouseEvent.MOUSE_MOVE, onStageMouseMove);
			stage.addEventListener( MouseEvent.MOUSE_WHEEL, onStageMouseMove );
			
			_currentAction = action;
			
			if ( action == RESIZE_LEFT ) //растяжение влево
			{
				_dragOffset = _activeSample.globalToLocal( new Point( event.stageX, 0 ) );
				
				dispatchEvent( new TracingEvent( TracingEvent.START_TRACING, true, false, _dragOffset, true ) );
				
				//cash history back event
				historyOp = new HistoryOperation( this, resizeLeftSample, _activeSample.name, _activeSample.offset );
				
			}
			else if ( action == RESIZE_RIGHT ) //растяжение вправо
			{
				_dragOffset = new Point( _activeSample.globalToLocal( new Point( event.stageX, 0 ) ).x - _activeSample.contentWidth, 0 );
				dispatchEvent( new TracingEvent( TracingEvent.START_TRACING, true, false, _dragOffset, true ) );
				
				//cash history back event
				historyOp = new HistoryOperation( this, resizeRightSample, _activeSample.name, _activeSample.duration );
			}
			else if ( action == START_DRAGGING )//Перетаскивание
			{	
				//Запоминаем положение семплов для отмены
				_dragInitiatorEvent = event;
				_dragOffset = new Point( event.localX, 5 );
			}
			else if ( action == DRAG_DROP ) //Вставка семпла из библиотеки или палитры
			{
				_dragOffset = new Point( _activeSample.contentWidth / 2.0, 0 );
				
				if ( _dragOffset.x > 300 )
				{
					_dragOffset.x = 100;
				}
				
				dispatchEvent( new TracingEvent( TracingEvent.START_TRACING, true, true, _dragOffset, true ) );
			}	
			else return;
			
			if ( vs )
			{
				if ( _currentAction == START_DRAGGING )
				{
					_resizeToLeftButton.visible = false;
					_resizeToRightButton.visible = false;
				}	
				else
				{
					_resizeToLeftButton.visible = _currentAction == RESIZE_LEFT;
					_resizeToRightButton.visible = _currentAction == RESIZE_RIGHT;	
				}	
				
				_actionButton.visible = false;
				vs.hovered = false;
				
				orderVisualSampleElements( vs );
			}	
		}	
		
		private function onSampleMouseUp( e : MouseEvent ) : void
		{
			var vs : VisualSample = e.currentTarget as VisualSample;
			
			if ( _currentAction <= START_DRAGGING )
			{
				if ( vs )
				{  
					//Ни ctrl ни shift не нажато, значит
					if ( ! e.shiftKey && ! e.ctrlKey ) 
					{
						clearSampleSelection( Vector.<VisualSample>( [ vs ] ) );
					}
					else
					{
						if ( e.ctrlKey ) //Нажата клавиша ctrl
						{
							if ( ! _lastSampleSelected )
							{
								vs.selected = false;
								removeFromSelected( vs );
							}	  
						}
						
						_lastPermanentSelection = true;
					}
					
					dispatchEvent( new SelectionSampleEvent( SelectionSampleEvent.CHANGE, _selectedSamples ) );
				}
				else _lastPermanentSelection = false; 
				
				_lastSampleSelected = false;
			}	
		  
			if ( vs )
			{
				removeElements();
				setRollOverVisualSampleState( vs );
			}
		}	
		
		private function onSampleMouseDown( e : MouseEvent ) : void
		{
			if ( _currentAction != NONE ) return;
		
				//Выделение
				var vs : VisualSample = e.currentTarget as VisualSample;
				
				if ( vs )
				{
					//Скрываем подсказку
					hideToolTip( vs );
					
					//Ни ctrl ни shift не нажато, значит
					if ( ! e.shiftKey && ! e.ctrlKey )
					{
						if ( ! _lastPermanentSelection && ! vs.selected )
						{
							clearSampleSelection();  
						} 
					}	
					
					if ( ! vs.selected )
					{
						vs.selected = true;
						addToSelected( vs );
						_lastSampleSelected = true;
					}
				}
			
				if ( e.target is ResizeLeftButton )
				{
					initSampleAction( e, e.currentTarget, RESIZE_LEFT );
				}
				else if ( e.target is ResizeRightButton )
				{
					initSampleAction( e, e.currentTarget, RESIZE_RIGHT );
				}
				else if ( e.target is ActionButton )
				{
					
				}	
				else
				{
					initSampleAction( e, e.currentTarget, START_DRAGGING );	
				}
				
		}
		
		private function addToSelected( vs : BaseVisualSample ) : void
		{
		  _selectedSamples.push( vs );
		}
		
		private function removeFromSelected( vs : BaseVisualSample ) : void
		{
			var i : int = 0;
			
			while( i < _selectedSamples.length )
			{
				if ( _selectedSamples[ i ] == vs )
				{
					_selectedSamples.splice( i, 1 );
					
					return;
				}	
				
				i ++;
			}
		}
		
		/**
		 * Снимает выделение со всех семплов
		 * exclude - выделение с которых не будет снято 
		 * 
		 */		
		public function clearSampleSelection( excludeList : Vector.<VisualSample> = null ) : void
		{
			var i : int = _selectedSamples.length - 1;
			
			while( i >= 0 )
			{
				var vs : VisualSample = _selectedSamples[ i ] as VisualSample;
				
				if ( vs )
				{
					var exclude : Boolean = false;
					
					//Проверяем необходимо ли, исключить этот семпл
					if ( excludeList )
					{
						var j : int = 0;
						
						while( j < excludeList.length )
						{
							exclude = excludeList[ j ] == vs;
							if ( exclude ) break;
							
							j ++;
						}	
					}	
					
					if ( ! exclude )
					{
						vs.selected = false;
						_selectedSamples.splice( i, 1 );
					}
				}		
				
				 i --;
			}
			
			_lastPermanentSelection = false;
		}
		
		/**
		 * Выбирает определенную дорожку 
		 * @param trackNumber номер дорожки
		 * 
		 */		
		public function selectTrack( trackNumber : int ) : void
		{
			_selectedTracks.push( trackNumber );
		}
		
		/**
		 * Cнимает выделение с определенной дорожки 
		 * @param trackNumber номер дорожки
		 * 
		 */		
		public function unselectTrack( trackNumber : int ) : void
		{
			var i : int = 0;
			
			while( i < _selectedTracks.length )
			{
				if ( _selectedTracks[ i ] == trackNumber )
				{
					_selectedTracks.splice( i, 1 );
					return;
				}	
				
				i ++;
			}	
		}
		
		/**
		 * Снимает выделение со всех дорожек 
		 * 
		 */		
		public function clearTrackSelection() : void
		{
		  _selectedTracks.length = 0;	
		}
		
		/**
		 * Удаляет выделенные в настоящий момент семплы 
		 * 
		 */
		public function deleteSelectedSamples() : void
		{
			/*push to history*/
			addActionToHistoryRemoveSamples( _selectedSamples );
			
			deleteSamples( _selectedSamples );
			clearSampleSelection();
		}	
		
		/**
		 * Удаляет указанные семплы 
		 * 
		 */		
		public function deleteSamples( samples : Vector.<BaseVisualSample> ) : void
		{
			var i : int = samples.length - 1;
			
			var numSelected : int = _selectedSamples.length;
			
			while( i >= 0 )
			{
				removeSample( samples[ i ] );
				
				i --;
			}
			
			if ( numSelected != _selectedSamples.length )
			{
				dispatchEvent( new SelectionSampleEvent( SelectionSampleEvent.CHANGE, _selectedSamples ) );
			}
		}
		
		/**
		 * Удаляет все имеющиеся семплы 
		 * 
		 */		
		public function clearAll() : void
		{
			var i : int = numChildren - 1;
			
			while( i >= 0 )
			{
				var s : BaseVisualSample = getChildAt( i ) as BaseVisualSample;
				
				if ( s )
				{
					removeSample( s );
				}	
				
				i --;
			}
			
			_selectedSamples.length = 0;
			_numSamples = 0;
		}	
		
		/**
		 * Выделяет все семплы севенсора 
		 * 
		 */		
		public function selectAllSamples() : void
		{
			clearSampleSelection();
			
			var i : int = 0;
			
			while( i < numChildren ) 
			{
				var vs : VisualSample = getChildAt( i ) as VisualSample;
				
				if ( vs )
				{
					
					vs.selected = true;
					addToSelected( vs );
				}	
				
				i ++;
			}
			
			dispatchEvent( new SelectionSampleEvent( SelectionSampleEvent.CHANGE, _selectedSamples ) );
		}
		
		public function selectSamplesUnderRect( rect : Rectangle ) : void
		{
			clearSampleSelection();
			
			var i : int = 0;
			
			while( i < numChildren )
			{
				var s : VisualSample = getChildAt( i ) as VisualSample;
				
				if ( s )
				{
					if ( rect.intersects( s.getBounds( this ) ) )	
					{
						s.selected = true;
						addToSelected( s );
					}	
				}	
				
				i ++;
			}	
		}
		
		/**
		 * Возвращает список ключевых записей в списке описателей семплов для буфера обмена 
		 * @param records - список записей
		 * @return Структура KeyRecords описывающая ключевые записи в группе
		 * 
		 */		
		private function getGroupKeyRecords( records : Vector.<SampleClipboardRecord> ) : KeyRecords
		{
			var result : KeyRecords;
			var i      : int = 0;
			
			while( i < records.length )
			{
				var record : SampleClipboardRecord = records[ i ];
				
				if ( i == 0 )
				{
					result = new KeyRecords( record );
				}
				else
				{
					//Верхняя граница
					if ( result.top.trackNumber > record.trackNumber )
					{
						result.top = record;
					}
					
					//Нижняя граница
					if ( result.bottom.trackNumber < record.trackNumber )
					{
						result.bottom = record;
					}
					
					//Левая граница
					if ( result.left.position > record.position )
					{
						result.left = record;
					}	
					
					//Правая граница
					if ( ( result.right.position + result.right.duration ) < ( record.position + record.duration ) )
					{
						result.right = record;
					}	
				}	
				
				i ++;
			}
			
			return result;
		}	
		
		private function showHint( text : String ) : void
		{
			HintManager.show( text );
		}
		
		private function showError( text : String ) : void
		{
			HintManager.show( text, true );
		}
		
		/**
		 * Перемещает копию выделенных в данный момент семплов в буфер обмена 
		 * @return - возвращает NaN, если не выбраны семплы для копирования или 
		 * положение в секундах правой границы скопированной группы семплов
		 */	
		public function copySelectedSamples( cut : Boolean = false, hint : Boolean = true ) : Number
		{
			return copySamples( _selectedSamples, cut, hint );
		}
		
		private function serializeSamples( samples : Vector.<BaseVisualSample>, setName : Boolean = true ) : Vector.<SampleClipboardRecord>
		{
			var i    : int = 0;
			var list : Vector.<SampleClipboardRecord> = new Vector.<SampleClipboardRecord>( samples.length );
			
			while( i < samples.length )
			{
				var s : BaseVisualSample = samples[ i ];
				var loop : AudioLoop = s.note ? s.note.source as AudioLoop : null;
				var name : String = setName ? s.name : null;
				
				if ( loop )
				{
					list[ i ] = new SampleClipboardRecord( name, s.trackNumber, s.note.start, s.note.source.length, loop.offset, s.description, loop.loop, loop.inverted );	
				}
				else
				{	
					list[ i ] = new SampleClipboardRecord( name, s.trackNumber, s.position, NaN, 0.0, s.description, true, false );
				}
				
				list[ i ].description = s.description;
				
				i ++;
			}
			
			return list;
		}	
		
		/**
		 * Перемещает копию указанных семплов в буфер обмена 
		 * @return - возвращает NaN, если не выбраны семплы для копирования или 
		 * положение в секундах правой границы скопированной группы семплов
		 */		
		public function copySamples( samples : Vector.<BaseVisualSample>, cut : Boolean = false, hint : Boolean = true ) : Number
		{
			if ( samples.length > 0 )
			{
				var i        : int = 0;
				var copyList : Vector.<SampleClipboardRecord> = serializeSamples( samples, false );
				
				//Переводим координаты скопированной группы семплов в локальные
				var keyRecords : KeyRecords = getGroupKeyRecords( copyList );
				//Запоминаем правую границу выделенной группы семплов
				var border : Number = cut ? keyRecords.left.position  : 
					                        keyRecords.right.position + keyRecords.right.duration;
				
				i = 0;
				
				while( i < copyList.length )
				{
					var record : SampleClipboardRecord = copyList[ i ];
					
					if ( record != keyRecords.left )
					{
						record.position    -= keyRecords.left.position;
					}	
					
					if ( record != keyRecords.top )
					{
						record.trackNumber -= keyRecords.top.trackNumber;
					}	
					
					
					i ++;
				}
				
				keyRecords.left.position = 0;
				keyRecords.top.trackNumber = 0;
				
				Clipboard.impl.set( copyList, Clipboard.SAMPLES );
				
				if ( hint )
				{
					showHint( 'Скопировано сэмплов : ' + copyList.length );
				}	
				
				dispatchEvent( new MarkerChangeEvent( MarkerChangeEvent.PLAYHEAD_POSITION_CHANGED, border ) );
				
				return border;
			}
			
			if ( hint )
			{
				showHint( 'Нечего копировать :) Нет ни одного выбранного сэмпла' );
			}	
			
			return NaN;
		}
		
		/**
		 * Копирует выделенные семплы в буффер обмена и удаляет их с дорожек 
		 * 
		 */		
		public function cutSelectedSamples() : Number
		{
			var newPos : Number = cutSamples( _selectedSamples );
			
			dispatchEvent( new SelectionSampleEvent( SelectionSampleEvent.CHANGE, _selectedSamples ) );
			
			return newPos;
		}
		
		public function invertSelectedSamples() : void
		{
			invertSamples( _selectedSamples );
			addActionToHistoryInvert( _selectedSamples );
		}	
		
		private function addActionToHistoryInvert( samples : Vector.<BaseVisualSample> ) : void
		{
			/*add to history*/
			var names : Vector.<String> = sampleListToSampleNames( samples );
			
			var backName    : String;
			var forwardName : String;
			
			if ( names.length == 1 )
			{
				backName    = 'Отменить обращение ' + samples[ 0 ].description.name;
				forwardName = 'Обратить ' + samples[ 0 ].description.name;
			}
			else
			{
				backName = 'Отменить обращение (сэмплов:' + names.length + ')';
				forwardName = 'Обратить (сэмплов:' + names.length + ')';
			}
			
			History.add( new HistoryRecord( new HistoryOperation( this, invertSamplesByNames, names ),
				new HistoryOperation( this, invertSamplesByNames, names ), backName, forwardName )
			);
		}
		
		public function invertSamples( samples : Vector.<BaseVisualSample> ) : void
		{
			if ( samples.length > 0 )
			{	
				var i : int = 0;
				
				while( i < samples.length )
				{
					var s    : VisualSample = VisualSample( samples [ i ] );
					var loop : AudioLoop    = AudioLoop( s.note.source );
					
					loop.inverted = ! loop.inverted;
					
					if ( ! s.loading )
					{
						s.attachToWave( ! loop.loop, loop.inverted, i == ( samples.length - 1 ) );
						s.invalidateAndTouchDisplayList();
					}
					
					i ++;
				}
				
				return;
			}
			
			showHint( 'Нечего обращать :) Нет ни одного выбранного сэмпла' );
		}
		
		public function automaticTuneOnOffSelectedSamples() : void
		{
			automaticTuneOnOffSamples( _selectedSamples );
			addActionToHistoryAutomaticTuneOnOffSamples( _selectedSamples );
		}
		
		private function addActionToHistoryAutomaticTuneOnOffSamples( samples : Vector.<BaseVisualSample> ) : void
		{
			/*add to history*/
			var names : Vector.<String> = sampleListToSampleNames( samples );
			
			var backName    : String;
			var forwardName : String;
			
			if ( names.length == 1 )
			{
				if ( _selectedSamples[ 0 ].note.source.loop )
				{
					backName    = 'Отменить включение автоподстройки ' + samples[ 0 ].description.name;
					forwardName = 'Включить автоподстройку ' + samples[ 0 ].description.name;
				}
				else
				{
					backName    = 'Отменить отключение автоподстройки ' + samples[ 0 ].description.name;
					forwardName = 'Выключить автоподстройку ' + samples[ 0 ].description.name;
				}
			}
			else
			{
				if ( _selectedSamples[ 0 ].note.source.loop )
				{
					backName    = 'Отменить включение автоподстройки (сэмплов:' + names.length + ')';
					forwardName = 'Включить автоподстройку (сэмплов:' + names.length + ')';
				}
				else
				{
					backName    = 'Отменить отключение автоподстройки (сэмплов:' + names.length + ')';
					forwardName = 'Выключить автоподстройку (сэмплов:' + names.length + ' )';
				}
			}
			
			History.add( new HistoryRecord( new HistoryOperation( this, automaticTuneOnOffSamplesByNames, names ),
				new HistoryOperation( this, automaticTuneOnOffSamplesByNames, names ), backName, forwardName )
			);
		}
		
		public function automaticTuneOnOffSamples( samples : Vector.<BaseVisualSample> ) : void
		{
			if ( samples.length > 0 )
			{	
				var i : int = 0;
				
				while( i < samples.length )
				{
					var s    : VisualSample = VisualSample( samples [ i ] );
					var loop : AudioLoop    = AudioLoop( s.note.source );
					
					loop.loop = ! loop.loop;
					s.attachToWave( ! loop.loop, loop.inverted, i == ( samples.length - 1 ) );
					afterChangeBPM( s );
					
					s.touch();
					
					orderVisualSampleElements( s );
					
					i ++;
				}
				
				return;
			}
			
			showHint( 'Немогу ничего сделать :) Нет ни одного выбранного сэмпла' );
		}	
		
		/**
		 * Копирует указанные семплы в буффер обмена и удаляет их с дорожек 
		 * 
		 */		
		public function cutSamples( samples : Vector.<BaseVisualSample> ) : Number
		{
			var newPos : Number = copySamples( samples, true, false );
			
			addActionToHistoryRemoveSamples( samples );
			
			deleteSamples( samples );
			
			if ( ! isNaN( newPos ) )
			{
				showHint( 'Вырезано сэмплов : ' + Clipboard.impl.data.length );
			}
			else
			{
				showHint( 'Нечего вырезать :) Нет ни одного выбранного сэмпла' );
			}	
			
			return newPos;
		}
		
		private function deserializeSamples( list : Vector.<SampleClipboardRecord> ) : Vector.<BaseVisualSample>
		{
			var i : int = 0;
			var sample  : VisualSample;
			var samples : Vector.<BaseVisualSample> = new Vector.<BaseVisualSample>( list.length ); 
			var item : SampleClipboardRecord;
			
			while( i < list.length )
			{
				item = list[ i ];
				
				//Забираем семпл из библиотеки
				var paletteSample : PaletteSample = _palette.add( item.description );
				var loop          : AudioLoop = paletteSample.ready ? new AudioLoop( paletteSample.source, _bpm, item.loop ) : 
					                                            new AudioLoop( new DummyAudioData( item.description.id, Routines.ceilLength( item.description.duration, item.description.bpm ), item.description.bpm, item.description.loop ), _bpm, item.loop );
				
				sample = new VisualSample();
				sample.position = item.position;
				sample.trackNumber = item.trackNumber;
				sample.description = item.description;
				
				if ( paletteSample.error )
				{
					sample.error = true;
				}
				else
				{
					sample.loading = ! paletteSample.ready;
				}
				
				if ( item.name )
				{
					sample.name = item.name;
				}	
				
				sample.note = new Note( item.position, loop );
					
				loop.offset = item.offset;
				loop.inverted = item.inverted;
				
				sample.loopDuration = loop.loopLength;
				
				if ( isNaN( item.duration ) )
				{
					sample.duration = sample.loopDuration;
				}
				else
				{	
					loop.length = item.duration;
					sample.duration = loop.length;	
				} 
				
				sample.offset = item.offset;
				
				if ( paletteSample.ready )
				{
					sample.attachToWave( ! item.loop, item.inverted );
				}
				else
				{
					//Если для этого загрузчика уже установлены слушатели, то не ставим их
					if ( ! getSampleById( item.sample_id ) )
					{
						setLoaderListeners( paletteSample.loader );
					}
				}
				
				
				samples[ i ] = sample;
			    
				i ++;
			}
			
			return samples;
		}	
		
		/**
		 * Вставляет семплы ( если это возможно ) из буфера обмена
		 * 
		 * @param trackNumber - номер дорожки относительно которой будет происходить вставка
		 * @param position - позиция в секундах относительно которой будет происходит вставка
		 * 
		 * @return - возвращает NaN, если размещение невозможно или 
		 * положение в секундах правой границы вставленной группы семплов
		 */	
		public function pasteFromClipboard( position : Number ) : Number
		{
			//Если с семплами не производиться каких либо операций
			//И формат данных буфера обмена подходящий
			if ( ( _currentAction == NONE ) && ( Clipboard.impl.dataType == Clipboard.SAMPLES ) )
			{
				//Если ни одна дорожка не выбрана
				if ( _selectedTracks.length > 0 )
				{
					var trackNumber : int = _selectedTracks[ _selectedTracks.length - 1 ];
					var records     : Vector.<SampleClipboardRecord> = Vector.<SampleClipboardRecord>( Clipboard.impl.data );
					var keyRecords  : KeyRecords = getGroupKeyRecords( records );
					var record      : SampleClipboardRecord;
					
					var i           : int = 0;
					
					//Проверяем можно ли разместить семплы в указанном положении
					//Проверка выхода за пределы дорожки справа
					var rightBorder : Number = position + keyRecords.right.position + keyRecords.right.duration;
					var ok : Boolean = ( rightBorder <= _duration ) &&
						( ( keyRecords.bottom.trackNumber + trackNumber ) < TimeLineParameters.MAX_NUM_TRACKS ); 
					
					if ( ok )
					{
						while( i < records.length )
						{
							record = records[ i ];
							
							ok = checkPlacement( getVisualSamples( record.trackNumber + trackNumber ),
								position + record.position, record.duration );
							
							if ( ! ok ) break;
							
							i ++;
						}
					}
					
					//Если можно разместить размещаем (Ура !!!!)
					if ( ok )
					{
						
						//Создаем дополнительные дорожки, если необходимо
						var numTracksToCreate : int = ( keyRecords.bottom.trackNumber + trackNumber ) - _numTracks + 1;
						
						if ( numTracksToCreate > 0 )
						{
							History.startCatching();
							_seq.sendCommand( new CreateTrackEvent( CreateTrackEvent.CREATE_TRACK, _numTracks, numTracksToCreate ) );
						}	
						
						i = 0;
						var sample  : BaseVisualSample;
						var samples : Vector.<BaseVisualSample> = deserializeSamples( records ); 
						
						//Коректируем положение группы семплов с учетом указанной позиции
						while( i < samples.length )
						{
							sample = samples [ i ];
							
							sample.position += position;
							sample.trackNumber += trackNumber;
							sample.note.start = sample.position;
							
							addSample( sample );
							
							i ++;
						}	
						
						/*addToHistory*/
						addActionToHistoryAddSamples( samples );
						
						if ( numTracksToCreate > 0 )
						{
							History.stopCatching();
						}	
						
						dispatchEvent( new MarkerChangeEvent( MarkerChangeEvent.PLAYHEAD_POSITION_CHANGED, rightBorder ) );
						
						return rightBorder;
					}
				}
				else
				{
					showHint( 'Выберите дорожку относительно которой будут размещаться скопированные сэмплы' );
				    return NaN;
				}	
			}
			
			if ( Clipboard.impl.dataType == Clipboard.SAMPLES )
			{
				showHint( 'Не удается разместить скопированные сэмплы' );
			}
			else
			{
				showHint( 'Нечего вставлять. Буфер обмена пустой.' );
			}	
			
			return NaN;
		}	
		
		private function clearDraggingParameters() : void
		{
			_activeSamples = null;
			_dragInitiatorEvent = null;
			_initialPositions = null;
			_groupLeft = null;
			_groupRight = null;
			_groupBottom = null;
			_groupTop = null;
		}	
		
		private function updateClonedSamples( clearParams : Boolean = false ) : void
		{
			var i : int = 0;
			
			while( i < _activeSamples.length )
			{
				var s : BaseVisualSample = _activeSamples[ i ];
				
				if ( s.note )
				{
					_seq.addNoteTo( s.note, s.trackNumber );
				}	
				
				i ++;
			}
			
			if ( clearParams )
			{
				clearDraggingParameters();
			}	
		}
		
		private function updateDraggingSamples( clearParams : Boolean = false  ) : void
		{
			var i : int = 0;
			
			while( i < _activeSamples.length )
			{
				var s : BaseVisualSample = _activeSamples[ i ];
				
				if ( s.note )
				{
					if ( s.trackNumber >= _startNumTracks )
					{
						_seq.addNoteTo( s.note, s.trackNumber );
					}	
				}	
				
				i ++;
			}
			
			if ( clearParams )
			{
				clearDraggingParameters();
			}
		}	
		
		/**
		 * Общее количество созданных семплов за все время работы 
		 */		
		private var totalSampleCounter : int = 0;
		
		private function getUnicalSampleName( s : BaseVisualSample ) : String
		{	
		   var id : String = getQualifiedClassName( s ).split( '::' )[ 1 ] + totalSampleCounter.toString(); 
		   
		   totalSampleCounter ++;
		   
		   return id;
		}
		
		private function samplesToSampleNames( samples : Vector.<BaseVisualSample> ) : Vector.<String>
		{
			var i            : int = 0;
			var names        : Vector.<String>    = new Vector.<String>( samples.length );
			
			while( i < samples.length )
			{
				names[ i ] =  samples[ i ].name;
				
				i ++;
			}
			
			return names;
		}
		
		private function sampleNamesToSamples( names : Vector.<String> ) : Vector.<BaseVisualSample>
		{
			var samples : Vector.<BaseVisualSample> = new Vector.<BaseVisualSample>( names.length );
			var i : int = 0;
			
			while( i < names.length )
			{
				samples[ i ] = BaseVisualSample( getChildByName( names[ i ] ) );
				
				i ++;
			}
			
			return samples;
		}	
		
		/**
		 * Добавляет в историю событие добавление семплов 
		 * @param samples
		 * 
		 */		
		private function addActionToHistoryAddSamples( samples : Vector.<BaseVisualSample> ) :  void
		{
			var names        : Vector.<String> = samplesToSampleNames( samples ); 
			var list         : Vector.<SampleClipboardRecord> = serializeSamples( samples );
			
			var backName : String;
			var forwardName : String;
			
			if ( list.length == 1 )
			{
				backName = 'Удалить ' + list[ 0 ].description.name;
				forwardName = 'Вставить ' + list[ 0 ].description.name;
			}
			else
			{
				backName = 'Удалить (сэмплов:' + list.length + ')';
				forwardName = 'Вставить (сэмплов:' + list.length + ')';
			}
			
			History.add( new HistoryRecord( new HistoryOperation( this, removeSamplesByNames, names ),
				new HistoryOperation( this, addSamplesByDescriptions, list ), backName, forwardName )
			);
		}
		
		/**
		 * Добавляет в историю событие удаление семплов 
		 * @param samples
		 * 
		 */		
		private function addActionToHistoryRemoveSamples( samples : Vector.<BaseVisualSample> ) :  void
		{
			var names        : Vector.<String> = samplesToSampleNames( samples ); 
			var list         : Vector.<SampleClipboardRecord> = serializeSamples( samples );
			
			var backName : String;
			var forwardName : String;
			
			if ( list.length == 1 )
			{
				backName = 'Добавить ' + list[ 0 ].description.name;
				forwardName = 'Удалить ' + list[ 0 ].description.name;
			}
			else
			{
				backName = 'Добавить (сэмплов:' + list.length + ')';
				forwardName = 'Удалить (сэмплов:' + list.length + ')';
			}
			
			History.add( new HistoryRecord( new HistoryOperation( this, addSamplesByDescriptions, list ), 
				new HistoryOperation( this, removeSamplesByNames, names ), backName, forwardName
			)
			);
		}
		
		/**
		 * Добавляет в историю событие перемещения семплов 
		 * 
		 */		
		private function addActionToHistoryMoveSamples() : void
		{
			var i                 : int = 0;
			var names             : Vector.<String> = samplesToSampleNames( _activeSamples );
			var posOffset         : Number = _initialPositions[ 0 ].position - _activeSamples[ 0 ].position;
			var trackNumberOffset : int = _initialPositions[ 0 ].trackNumber - _activeSamples[ 0 ].trackNumber;
			
			//Если ничего не произошло - то ничего и не делаем
			if ( ( posOffset == 0.0 ) && ( trackNumberOffset == 0 ) )
			{	
				return;
			}
			
			var backName : String;
			var forwardName : String;
			
			if ( names.length == 1 )
			{
				backName = 'Отменить перемещение ' + _activeSamples[ 0 ].description.name;
				forwardName = 'Переместить ' + _activeSamples[ 0 ].description.name;
			}
			else
			{
				backName = 'Отменить перемещение (сэмлов:' + names.length + ')';
				forwardName = 'Переместить (сэмлов:' + names.length + ')';
			}
			
			History.add( new HistoryRecord( new HistoryOperation( this, moveSamples, names, posOffset, trackNumberOffset ),
				                            new HistoryOperation( this, moveSamples, names, - posOffset, - trackNumberOffset ), backName, forwardName ) ); 
						 
		}	
		
		private function onStageMouseUp( e : MouseEvent ) : void
		{
			//Для предотвращения нескольких событий при выходе мыши за границы браузера
			if ( _currentAction == NONE )
			{
				return;
			}		
			
			stage.removeEventListener( MouseEvent.MOUSE_UP, onStageMouseUp/*, true*/ );
			stage.removeEventListener( MouseEvent.MOUSE_MOVE, onStageMouseMove );
			stage.removeEventListener( MouseEvent.MOUSE_WHEEL, onStageMouseMove );
			
			/*add to history*/
			if ( _currentAction == RESIZE_LEFT )
			{
				History.add( new HistoryRecord( historyOp, new HistoryOperation( this, resizeLeftSample, _activeSample.name, _activeSample.offset ), 'Отменить изменение длины сэмпла ' + _activeSample.description.name, 'Измененить длину сэмпла ' + _activeSample.description.name ) );
				historyOp = null;
				_seq.calculateCategory( _activeSample.trackNumber );
			}	
			else if ( _currentAction == RESIZE_RIGHT )
			{	
				History.add( new HistoryRecord( historyOp, new HistoryOperation( this, resizeRightSample, _activeSample.name, _activeSample.duration ), 'Отменить изменение длины сэмпла ' + _activeSample.description.name, 'Измененить длину сэмпла ' + _activeSample.description.name ) );
				historyOp = null;	
				_seq.calculateCategory( _activeSample.trackNumber );
			}
			else
			if ( ( _currentAction == DRAGGING ) || ( _currentAction == CLONING ) )
			{
				dispatchEvent( new TrackerEvent( TrackerEvent.STOP_SAMPLE_DRAGGING ) );
				
				//Если перенести семплы в указанное место нельзя, то возвращаем их оттуда откуда взяли
				if ( _draggingStatus == DRAGGING_STATUS_NO )
				{
					_currentAction = _currentAction == DRAGGING ? UNDO_DRAGGING : UNDO_CLONING;	
					undoDragging();
				}
				else
				{
                  //Если создавать дорожки не надо
				  if ( _numTracksWillBeCreated == 0 )
				  {
					  if ( _currentAction == CLONING )
					  {   
						  /*add action to history*/
						  addActionToHistoryAddSamples( _activeSamples );
						  
						  updateClonedSamples();
					  }
					  else
					  {  
						  /*add action to history*/
						  addActionToHistoryMoveSamples();
					  }
					  
					  clearDraggingParameters();
					  
				  }//Необходимо создать дорожки
				  else
				  {
					  //Посылаем секвенсору команды для создания необходимого количества дорожек
					  var i : int = 0;
					  
					  History.startCatching();
					  
					  _seq.sendCommand( new CreateTrackEvent( CreateTrackEvent.CREATE_TRACK, _startNumTracks, _numTracksWillBeCreated ) );
					  
					  if ( _currentAction == CLONING )
					  {
						  /*add action to history*/
						  addActionToHistoryAddSamples( _activeSamples );
						  setTimeout( updateClonedSamples, UPDATE_TIME, true );  
					  }
					  else
					  {
						  /*add action to history*/
						  addActionToHistoryMoveSamples();
						  setTimeout( updateDraggingSamples, UPDATE_TIME, true );  
					  }
					  
					  History.stopCatching();
				  } 
				}
				
				//Очищаем состояние курсора
				_currentCursor = null;
				CursorManager.removeAllCursors();
			}	
			
			_slipingInc = 0;
			_sliping = false;
			_firstSamples = null;
			
			if ( _currentAction != START_DRAGGING )
			{
				dispatchEvent( new TracingEvent( TracingEvent.STOP_TRACING ) );
			}
			
			if ( _currentAction > NONE )
			{
				_currentAction = NONE;
			}
			
			var vs : VisualSample = _activeSample as VisualSample;
			
			if ( vs )
			{
				var sampleUnderPoint : BaseVisualSample = getSampleUnderPoint( e.stageX, e.stageY );
				
				if ( ! sampleUnderPoint )
				{
					_resizeToLeftButton.visible = false;
					_resizeToRightButton.visible = false;
					vs.hovered = false;
					//orderVisualSampleElements( vs, true );
				}
			}
		}	
		
		/**
		 * Ищет семпл под указанными глобальными координатами 
		 * @param stageX
		 * @param stageY
		 * @return возвращает null если ничего не найдено
		 * 
		 */		
		private function getSampleUnderPoint( stageX : Number, stageY : Number ) : BaseVisualSample
		{
			var i : int = 0;
			
			while( i < numChildren )
			{
				var s : BaseVisualSample = getChildAt( i ) as BaseVisualSample;
				
				if ( s )
				{
					if ( s.hitTestPoint( stageX, stageY ) )
					{
						return s;
					}
				}
				
				i ++;
			}
			
			return null;
		}
		
		private function draggingHandler( timePos : Number, pos : Point ) : void
		{
			var i : int = 0;
			var s : BaseVisualSample;
			
			//На сколько произошло смещение
			var dPos : Number = timePos - _activeSample.position;
			var useSticking : Boolean = true;
			
			if ( _groupLeft.position + dPos < 0 )
			{
				dPos = - _groupLeft.position;
				useSticking = false;
			}
			else if ( ( _groupRight.position + dPos + _groupRight.duration  ) > _duration )
			{
				dPos = _duration - _groupRight.position - _groupRight.duration;
				useSticking = false;
			}
			
			//Определяем номер дорожки над которой перемещается образец
			var _trackNumber : int = cursorPositionToTrackNumber( pos.y, true );
			
			//Определяем момент перехода на следующую дорожку
			if ( ( _trackNumber != -1 ) && ( _trackNumber != _activeSample.trackNumber ) )
			{
				//Проверяем на выход за верхние пределы дорожек
				var dTrackNumber : int = _trackNumber - _activeSample.trackNumber;
				
				if ( ( _groupTop.trackNumber + dTrackNumber >= 0 ) &&
					 ( _groupBottom.trackNumber + dTrackNumber < _virtualNumTracks )
					)
				{
					var newTrackNumber : int;
					
					//Меняем номер дорожки
					while( i < _activeSamples.length )
					{
						s = _activeSamples[ i ];
						
						newTrackNumber = s.trackNumber + dTrackNumber;
						
						if ( _currentAction == DRAGGING && s.note )
						{
							//Переход с реальной дорожки на реальную
							if ( ( s.trackNumber < _startNumTracks ) && ( newTrackNumber < _startNumTracks ) )
							{
								_seq.removeNoteFrom( s.note, s.trackNumber );
								_seq.addNoteTo( s.note, newTrackNumber );
							}	
							else
							//Переход с виртуальной дорожки на реальную
							if ( ( s.trackNumber >= _startNumTracks ) && ( newTrackNumber < _startNumTracks  ) )
							{
								_seq.addNoteTo( s.note, newTrackNumber );	
							}	
							else  //Переход с реальной дорожки на виртуальную
							if ( ( s.trackNumber < _startNumTracks ) && ( newTrackNumber >= _startNumTracks ) )
							{
								_seq.removeNoteFrom( s.note, s.trackNumber );
							}	
								
						}	
						
						s.trackNumber = newTrackNumber;
						
						i ++;
					}
					
					//Определяем сколько дорожек необходимо создать
					newTrackNumber = Math.max( _groupBottom.trackNumber - _startNumTracks + 1, 0 );
					
					//Если количество дорожек изменилось, то отправляем событие для отрисовки дополнительных дорожек
					if ( newTrackNumber != _numTracksWillBeCreated )
					{
						_numTracksWillBeCreated = newTrackNumber;
						dispatchEvent( new TrackerEvent( TrackerEvent.VIRTUAL_NUM_TRACKS_CHANGED, _startNumTracks + newTrackNumber, _virtualNumTracks ) );
					}	
					
					//Кешируем изменения
					i = 0;
					
					while( i < _activeSamples.length )
					{
						s = _activeSamples[ i ];
						
						if ( s.trackNumber < _numTracks )
						{
							_initialPositions[ i ].trackSamples = getVisualSamples( _activeSamples[ i ].trackNumber );
						}	
						else
						{
							_initialPositions[ i ].trackSamples = null;
						}	
						
					    i ++;
					}	
				}
			}	
			
			if ( useSticking )
			{
				if ( _stickToOtherLoops )
				{
					//Приклеиваемся стык в стык к ближайшему семплу
					if ( dPos > 0 ) //Справа
					{
						s = getNearestSample( _initialPositions[ _groupRightIndex ].trackSamples,
							_groupRight.position + dPos, _groupRight.duration,
							_groupRight, 1 );
						if ( s )
						{
							if ( Math.abs( s.position - _groupRight.position - _groupRight.duration - dPos ) <= _stickingArea )
							{
								dPos = s.position - _groupRight.position - _groupRight.duration;
								_sliping = true;
							}	
						}	
					}
					else //Слева
					{
						s = getNearestSample( _initialPositions[ _groupLeftIndex ].trackSamples,
							_groupLeft.position + dPos, _groupLeft.duration,
							_groupLeft, -1 );
						
						if ( s )
						{
							if ( Math.abs( _groupLeft.position - s.position - s.duration - dPos ) <= _stickingArea )
							{
								dPos = - ( _groupLeft.position - s.position - s.duration );
								
								_sliping = true;
							}	
						}	
						
					}	
				}	
				 
				    /*Приклеиваемся началом*/
				    if ( _stickToGrid && ! _sliping )
					{
						var sPoint : Number = getNearestStickPoint( timePos );
						
						if ( sticking( timePos, sPoint ) )
						{
							dPos = sPoint - _activeSample.position;
						}
						else  //и концом семпла к сетке
						{
							var sEnd : Number = timePos + _activeSample.duration;
							sPoint = getNearestStickPoint( sEnd );
							
							if ( sticking( sEnd, sPoint ) )
							{
								dPos = sPoint - sEnd;
							}	
						}
					}
					
			}	  
			
			//Изменяем положение группы семплов и определяем можно ли разместить семплы в указанном месте
			i = 0;
			_draggingStatus = DRAGGING_STATUS_YES;
			
			while( i < _activeSamples.length )
			{
				s = _activeSamples[ i ];
				
				//Устанавливаем новое положение
				s.position += dPos;
				
				if ( s.note )
				{
					s.note.start = s.position;
				}	
				
				//Определяем статус
				var placement : Boolean = checkPlacement( _initialPositions[ i ].trackSamples, s.position, s.duration, _activeSamples );
				
				//Отключаем звучание этого семпла, если его нельзя здесь размещать или включаем, если можно
				if ( _currentAction == DRAGGING && s.note )
				{
					_seq.lockNote( s.note, ! placement );
				}
				
				if ( ! placement )
				{
					_draggingStatus = DRAGGING_STATUS_NO;
				}	
				 	
				i ++;
			}
		}
		
		private function resizeLeftHandler( timePos : Number ) : void
		{
			var useSticking : Boolean = true;
			var stickPos : Number;
			
			if ( timePos < 0 ) //Семпл не должен вылезать за левые пределы дорожки
			{
				timePos = 0;
				useSticking = false;
			}
			
			var offset : Number = _activeSample.position - timePos;	
			
			//Запрещаем смещать меньше размера одной доли ( если длина сэмпла меньше одной доли, то меньше длины сэмпла )
			if ( ( _activeSample.duration + offset ) < Math.min( _stickInterval, _activeSample.loopDuration ) )
			{
				offset = - ( _activeSample.duration - _stickInterval );
				timePos = _activeSample.position - offset;
				useSticking = false;
			}	
			
			//Прилипание к левой границе петли
			if ( useSticking && _stickToLoopsBorder )
			{
				stickPos = leftLoopBorderNearestOffset( _activeSample, offset );
				
				if ( leftLoopBorderSticking( _activeSample, stickPos, offset ) )
				{
					offset = _activeSample.offset - stickPos;
					timePos = _activeSample.position - offset;
					
					useSticking = false;
				}	
			}	
				
			//Прилипание к сетке
			if ( useSticking && _stickToGrid )
			{
				stickPos = getNearestStickPoint( timePos );
				
				if ( sticking( timePos, stickPos ) )
				{
					offset = _activeSample.position - stickPos;
					
					timePos = stickPos;
					useSticking = false;
				}	
			}
			
			if ( ! checkPlacement( _firstSamples, timePos, _activeSample.duration + offset, _activeSample ) )
			{
				var s : BaseVisualSample = getNearestSample( _firstSamples, timePos, _activeSample.duration + offset, _activeSample, -1 );
				
				if ( s )
				{
					timePos = s.position + s.duration;
					offset = _activeSample.position - timePos;	
				}
				else
				{
					timePos = _activeSample.position;
					offset = 0;
				}	
			}
			
			_activeSample.position     = timePos;
			_activeSample.offset      -= offset;
			_activeSample.duration    += offset;
			
			if ( _activeSample.note )
			{
				var loop : AudioLoop = _activeSample.note.source as AudioLoop;
				
				_activeSample.note.start = _activeSample.position;
				
				if ( loop )
				{
					loop.offset = _activeSample.offset;
					loop.length = _activeSample.duration;
				}	
			}	
		}
		
		private function resizeRightHandler( timePos : Number ) : void
		{	
			var useSticking : Boolean = true;
			var stickPos : Number;
			
			if ( timePos > _duration )
			{
				timePos = _duration;
				useSticking = false;
			}
			
			//Запрещаем смещать меньше размера одной доли ( если длина сэмпла меньше одной доли, то меньше длины сэмпла )
			if ( timePos > _activeSample.position + Math.min( _stickInterval, _activeSample.loopDuration ) )
			{
				var offset : Number = timePos - _activeSample.position - _activeSample.duration;
					
				if ( _stickToLoopsBorder && useSticking &&	rightLoopBorderSticking( _activeSample, offset ) )
				{
					offset = rightLoopBorderNearestOffset( _activeSample, offset );
					useSticking = false;
				}
				
				//Прилипание к сетке
				if ( useSticking && _stickToGrid )
				{
					stickPos = getNearestStickPoint( timePos );
					
					if ( sticking( timePos, stickPos ) )
					{
						offset = stickPos - _activeSample.position - _activeSample.duration;
						useSticking = false;
					}	
				}
					
				//Проверяем не залезаем ли мы на другие семплы
				if ( ! checkPlacement( _firstSamples, _activeSample.position, _activeSample.duration + offset, _activeSample ) ) //Не залезаем
				{
					//Коректируем значение длины "петли", для плотной пристыкоски семплов друг к другу
					var s : BaseVisualSample = getNearestSample( _firstSamples, _activeSample.position, _activeSample.duration + offset, _activeSample, 1 );
					if ( s )
					{
						offset = s.position - _activeSample.position - _activeSample.duration;
					}
					else offset = 0;
				}
				
				_activeSample.duration += offset;
			}
			else
			{
				_activeSample.duration = _stickInterval;
			}
			
			if ( _activeSample.note )
			{
				var loop : AudioLoop = _activeSample.note.source as AudioLoop;
				
				if ( loop )
				{
					loop.length = _activeSample.duration;
				}	
			}	
		}
		
		private function dragDropHandler( timePos : Number, pos : Point ) : void
		{
			var useSticking : Boolean = true;
			var stickPos : Number;
			
			if ( ( timePos < 0 ) || ( _activeSample.duration > _duration ) )
			{
			   timePos = 0;
			   useSticking = false;
			}
			else if ( ( timePos + _activeSample.duration ) > _duration )
			{
			   timePos = _duration - _activeSample.duration;
			   useSticking = false;
			}
			
			//Определяем номер дорожки над которой перемещается образец
			var _trackNumber : int = cursorPositionToTrackNumber( pos.y );
			
			//Определяем момент перехода на следующую дорожку
			if ( ( _trackNumber != -1 ) && ( _trackNumber != _activeSample.trackNumber ) )
			{
				_activeSample.trackNumber = _trackNumber;
				
				_firstSamples = getVisualSamples( _trackNumber );
			}
			
			if ( useSticking )
			{
				if ( _stickToOtherLoops )
				{
					//Приклеиваемся стык в стык к ближайшему семплу
					var dPos : Number = timePos - _activeSample.position;
					var s    : BaseVisualSample = getNearestSample( _firstSamples, timePos, _activeSample.duration, _activeSample, dPos );
					
					if ( s )
					{
						if ( dPos > 0 ) //Справа
						{
							
							if ( Math.abs( s.position - timePos - _activeSample.duration ) <= _stickingArea )
							{
								timePos = s.position - _activeSample.duration;
								_sliping = true;
							}	
							
						}
						else //Слева
						{
							
							if ( Math.abs( timePos - s.position - s.duration ) <= _stickingArea )
							{
								timePos = s.position + s.duration;
								_sliping = true;
							}
						}
					}
				}	
				
				/*Приклеиваемся началом*/
				if ( _stickToGrid && ! _sliping )
				{
					stickPos = getNearestStickPoint( timePos );
					
					if ( sticking( timePos, stickPos ) )
					{
						dPos = stickPos - _activeSample.position;
					}
					else  //и концом семпла к сетке
					{
						var sEnd : Number = timePos + _activeSample.duration;
						stickPos = getNearestStickPoint( sEnd );
						
						if ( sticking( sEnd, stickPos ) )
						{
							dPos = stickPos - sEnd;
						}	
					}
				}
			}		
			
			if ( checkPlacement( _firstSamples, timePos, _activeSample.duration, _activeSample ) )
			{
			DragManager.showFeedback( DragManager.COPY );
			}
			else
			{
			DragManager.showFeedback( DragManager.REJECT );
			}
			
			_activeSample.position = timePos;
		}	
		
		private function afterAction( s : BaseVisualSample ) : void
		{
			orderSample( s );
			s.touch();
			
			s.visible = sampleIsVisible( s );
			
			if ( s.visible )
			{
				var vs : VisualSample = s as VisualSample;
				
				if ( vs )
				{
					orderVisualSampleElements( vs );	
				}
			}	
		}
		
		private function onStageMouseMove( e : MouseEvent ) : void
		{
			//Если нету семпла с которым работаем то ничего не делаем
			if ( ! _activeSample ) return;
			
			if ( ! _sliping )
			{
				var pos : Point = globalToLocal( new Point( e.stageX - _dragOffset.x, e.stageY - _dragOffset.y ) );
				var timePos  : Number = Math.round( pos.x * _scale );
				
				var needToStick : Boolean = _scale > FREE_MOVING_SCALE;
				
				if ( _activeSample.note )
					{
						var sampleIsLoop : Boolean = _activeSample.note.source.loop;
						
						if ( ! sampleIsLoop ) //Семплы "не петли"
						{
							needToStick = false;/*( _currentAction != RESIZE_LEFT ) && ( _currentAction != RESIZE_RIGHT );*/
						}
					} 
					
				
				if ( needToStick )
				{
					timePos = getNearestStickPoint( timePos );
				}
				
				if ( _currentAction == START_DRAGGING )
				{
					if ( ( Math.abs( _dragInitiatorEvent.stageX - e.stageX ) > START_DRAGGING_OFFSET ) ||
					     ( Math.abs( _dragInitiatorEvent.stageY - e.stageY ) > START_DRAGGING_OFFSET )
					    )
					{
						//CLONE or DRAG
						if ( e.ctrlKey )
						{
							_activeSample = cloneSelected();
							_activeSamples = _clonedSamples;
							_currentAction = CLONING;
						}
						else
						{
							_activeSamples = _selectedSamples.slice( 0 );
							_currentAction = DRAGGING;
						}
						
						saveInitialPosition();
						dispatchEvent( new TrackerEvent( TrackerEvent.START_SAMPLE_DRAGGING ) );
						dispatchEvent( new TracingEvent( TracingEvent.START_TRACING, true, true, _dragOffset, true ) );
					}	
				}	
				else if ( _currentAction == DRAGGING )
				{
					draggingHandler( timePos, pos );
				}
				else if ( _currentAction == CLONING )
				{
					draggingHandler( timePos, pos );
				}	
				else if ( _currentAction == RESIZE_LEFT )
				{
					resizeLeftHandler( timePos );
				}
				else if ( _currentAction == RESIZE_RIGHT )
				{
				  resizeRightHandler( timePos );	
				}
				else if ( _currentAction == DRAG_DROP )
				{
					dragDropHandler( timePos, pos );
				}
				
				//Действия после выполнения действия
				if ( ( _currentAction == DRAGGING ) || ( _currentAction == CLONING ) ) 
				{
				  var i  : int = 0; 
				  
				  while( i < _activeSamples.length )
				   { 
					 afterAction( _activeSamples[ i ] );
					  
					 i ++;
				   }
				  
				  //Устанавливаем курсор отображающий статус перетасивания
				  if ( _draggingStatus == DRAGGING_STATUS_YES )
				   {
						  if ( _currentAction == DRAGGING )
						  {
							  if ( _currentCursor )
							  {
								  _currentCursor = null;
								  CursorManager.removeAllCursors();
							  }  
						  }	  
						  else if ( _currentCursor != copyCursor )
						  {
							  _currentCursor = copyCursor;
							  CursorManager.removeAllCursors();
							  CursorManager.setCursor( _currentCursor ); 
						  }	
					}
					else if ( _draggingStatus == DRAGGING_STATUS_NO )
					  {
						  if ( _currentCursor != rejectCursor )
						  {
							  _currentCursor = rejectCursor;
							  CursorManager.removeAllCursors(); 
							  CursorManager.setCursor( _currentCursor );
						  }	
					  }     
				}
				else
				{
					afterAction( _activeSample );
				}		
			}	  
			else
			{
				nextSlipping();  	  
			}
		}
		
		/**
		 * Возвращает номер дорожки к которой относить указанный семпл 
		 * @param y - локальные координаты по оси y
		 * @return номер дорожки или -1, если необходимой дорожки не найдено
		 * 
		 */		
		public function cursorPositionToTrackNumber( y : Number, useVirtualNumTracks : Boolean = false ) : int
		{
		  if ( ( y < _vsp ) || ( y > _vsp + scrollHeight ) )
		   return -1;	  
			
		  var result : int = Math.floor( y / _trackHeight );
		  
		  if ( useVirtualNumTracks )
		  {
			  if ( result >= _virtualNumTracks )
				  return -1;   
		  }	  
		  else
		  {
			  if ( result >= _numTracks ) return -1; 
		  }	  
		  
		  if ( result < 0 ) return -1;
		  
		  return result;
		}	
		
		/**
		 * Возвращает самый ближайший семпл по отношению к указанному, в указанном направлении 
		 * @param _position - положение объекта
		 * @param _duration - длительность объекта
		 * @param instance  - для какого семпла, нужно найти ближайший
		 * @param _direction - с какой стороны искать ближайших ( слева - _direction < 0 ), ( справа - _direction > 0 ). 0 - Сам пытается определить с какой стороны искать
		 * @return ближайший найденный семпл
		 * 
		 */		
		private function getNearestSample( _samples : Vector.<BaseVisualSample>, _position : Number, _duration : Number, instance : BaseVisualSample, _direction : Number = 0 ) : BaseVisualSample
		{
			var _nearest     : Number;
			var _s           : BaseVisualSample;
			var _count       : int = 0;
			
			if ( _direction == 0 )
			{
				_direction = _position - instance.position;	
			}
			
			//Создаем список всех пересечений
			for ( var i : int = 0; i < _samples.length; i ++ )
			{
				var s : BaseVisualSample = _samples[ i ];
				
				if ( s && instance != s )
				{
					//Справа
					if ( _direction > 0 )
					{
						if ( instance.position  < s.position  )
						{
							if ( _count == 0 )
							{
								_nearest = s.position;
								_s = s;
							}
							else 
							{
								if ( s.position < _nearest )
								{
									_nearest = s.position;
									_s = s;
								}
							}
							_count ++;
						}		
					}
					else //Слева
					{
						if ( instance.position > s.position  )
						{
							if ( _count == 0 )
							{
								_nearest = s.position;
								_s = s;
								
							}else 
							{
								if ( s.position > _nearest )
								{
									_nearest = s.position;
									_s = s;
								} 
							}
							_count ++;
						}			
					}
				}	
			}
			
			if ( _s ) return _s;
			
			return null;
		}
		
		/**
		 * Определяет может ли указанный семпл быть размещенным на дорожке 
		 * @param _samples - список семплов для проверки
		 * @param s семпл для проверки
		 * @return true, если можно разместить
		 */		
		private function checkPlacement( _samples : Vector.<BaseVisualSample>, _position : Number, _duration : Number, instance : Object = null ) : Boolean
		{
			if ( _samples ) 
			{
				var instances : Vector.<BaseVisualSample> = instance as Vector.<BaseVisualSample>;
				
				for ( var i : int = 0; i < _samples.length; i ++ )
				{
					var s : BaseVisualSample = _samples[ i ];
					var check : Boolean = true;
					
					if ( instances )
					{
						var j  : int = 0;
						
						while( j < instances.length )
						{
							if ( instances[ j ] == s )
							{
								check = false;
								break;
							}	
							
							j ++;
						}	
					}
					else
					{
						check = ( s != instance );
					}	
					
					if ( check )
					{
						var intersection : Rectangle = new Rectangle(  s.position, 1,  s.duration, 1 ).intersection( new Rectangle( _position, 1, _duration, 1 ) );
						//trace( intersection );
						//Оставляем с погрешностью меньше 1.0
						if ( intersection.width > 1.0 )
						{
							return false;
						}
					}
				}	
			}	
			
			return true;
		}
		
		/**
		 * Проверяет нужно ли прилипнуть к этой точке или нет 
		 * @param time - время точки в секундах
		 * @return - прилипнуть / неприлипнуть
		 * 
		 */		
		private function sticking( time : Number, stickPoint : Number ) : Boolean
		{
			_sliping =  Math.abs( time - stickPoint ) <= _stickingArea;
				
			return _sliping;
		}
		
		/**
		 * Возвращает ближайшую временную точку на треке к которой можно "прилипнуть" 
		 * @param time время точки в секундах
		 * @return скоректированное значение
		 * 
		 */		
		private function getNearestStickPoint( time : Number ) : Number
		{
			return Math.round( time / _stickInterval ) * _stickInterval;
		}
		
		/**
		 * Определяет нужно ли "зависнуть" в этой точке при растягивании семпла влево 
		 * @param s - семпл
		 * @return "зависнуть" / "независать"
		 * 
		 */		
		private function leftLoopBorderSticking( s : BaseVisualSample, stickOffset : Number, offset : Number ) : Boolean
		{
			_sliping = ( Math.abs( s.offset - offset - stickOffset  ) <= _stickingArea );
			
			return _sliping;
		}
		
		/**
		 * Возвращает смещение на которое нужно сместиться чтобы прилипнуть к границе "петли" слева 
		 * @param s - семпл
		 * @offset - новое значение смещения для коректировки
		 * @return скоректированное значение
		 * 
		 */	
		private function leftLoopBorderNearestOffset( s : BaseVisualSample, offset : Number ) : Number
		{
			return Math.round( ( s.offset - offset ) / s.loopDuration ) * s.loopDuration;
		}	
		
		
		/**
		 * Определяет нужно ли "зависнуть" в этой точке при растягивании семпла вправо 
		 * @param s - семпл
		 * @return "зависнуть" / "независать"
		 * 
		 */		
		private function rightLoopBorderSticking( s : BaseVisualSample, offset : Number ) : Boolean
		{
			var duration : Number = s.duration + offset - s.localOffset;
			
			offset = Math.abs( duration - Math.round( duration / s.loopDuration ) * s.loopDuration );
			
			_sliping = ( offset <= _stickingArea );
			
			return _sliping;
		}
		
		/**
		 * Возвращает смещение на которое нужно сместиться чтобы прилипнуть к границе "петли" справа 
		 * @param s - семпл
		 * @offset - новое значение смещения для коректировки
		 * @return скоректированное значение
		 * 
		 */
		private function rightLoopBorderNearestOffset( s : BaseVisualSample, offset : Number ) : Number
		{
			var duration : Number = s.duration + offset - s.localOffset;
			var wholeDuration: Number = Math.round( duration / s.loopDuration ) * s.loopDuration;
			
			return  wholeDuration - s.duration + s.localOffset; 
		}
		
		/**
		 * Возвращает список семплов принадлежащих определенной дорожке 
		 * @param _trackNumber - номер дорожки
		 * @return список семплов принадлежащих определенной дорожке
		 * 
		 */		
		private function getVisualSamples( _trackNumber : int ) : Vector.<BaseVisualSample>
		{
			if ( numChildren > 0 )
			{
				var i      : int = 0;
				var result : Vector.<BaseVisualSample> = new Vector.<BaseVisualSample>();
				
				while( i < numChildren )
				{
					var s : BaseVisualSample = getChildAt( i ) as BaseVisualSample;
					
					if ( s )
					{
						if ( s.trackNumber == _trackNumber )
						{
							result.push( s );
						}		
					}	
					
					i ++;
				}	
			}
			
			return result && result.length > 0 ? result : null;
		}
		
		private function orderVisibleSamples() : void
		{
			var samples : Vector.<BaseVisualSample> = getVisibleSamples();
			
			if ( samples )
			{
				var i : int = 0;
				
				while( i < samples.length )
				{
					var s : BaseVisualSample = samples[ i ];
					
					//Упорядочиваем название и кнопку вызова меню для семплов типа VisualElements
					var vs : VisualSample = s as VisualSample;
					
					if ( vs )
					{
						orderVisualSampleElements( vs, true );
					}	
					
					i ++;
				}
			}
		}
		
		private function orderSamples() : void
		{
			if ( numChildren > 0 )
			{
				var i : int = 0;
				
				while( i < numChildren )
				{
					var s : BaseVisualSample = getChildAt( i ) as BaseVisualSample;
					
					if ( s )
					{
						orderSample( s, true );	
						s.touch();
					}	
						
					i ++;
				}
			}		
		}
		
		private function orderAfterChangeBPM() : void
		{
			if ( numChildren > 0 )
			{
				var i : int = 0;
				
				while( i < numChildren )
				{
					var s : BaseVisualSample = getChildAt( i ) as BaseVisualSample;
					
					if ( s )
					{
						afterChangeBPM( s );
						orderSample( s );
						s.touch();
					}	
					
					i ++;
				}
			}
		}	
		
		private function afterChangeBPM( s : BaseVisualSample ) : void
		{
			if ( s.note )
			{
				s.position     = s.note.start;
				s.duration     = s.note.source.length;
				
				var loop : AudioLoop = s.note.source as AudioLoop; 
				
				if ( loop )
				{
					s.loopDuration = loop.loopLength;
					s.offset = loop.offset;
				}	
				else
				{
					s.loopDuration = s.duration;
				}	
			}
		}	
		
		private function orderSample( s : BaseVisualSample, update : Boolean = false ) : void
		{
			s.x = s.position / _scale;
			s.y = s.trackNumber * _trackHeight;
			
			if ( update )
			{
				s.scale = _scale;	
			}
		}	
		
		private function orderVisualSampleElements( s : VisualSample, justRefresh : Boolean = false, useCurrentAction : Boolean = true ) : void
		{
		  	var hovered : Boolean = useCurrentAction ? s.hovered && ( _currentAction <= NONE ) : s.hovered;
		    var aE      : Base;
			
			if ( s.indicator  )
			{
				aE = s.indicator;
			}
			else if ( hovered )
			{
				aE = _actionButton;
			}	
  			
			//Просто необходимо обновить, поэтому кнопки растяжение в этом случае не трогаем
			if ( ! justRefresh )
			{
				if ( _resizeToLeftButton.visible )
				{
					_resizeToLeftButton.x = 0;
					_resizeToLeftButton.y  =  ( s.contentHeight - _resizeToLeftButton.contentHeight ) / 2;
				}	
				
				if ( _resizeToRightButton.visible )
				{
					_resizeToRightButton.x = s.contentWidth - _resizeToRightButton.contentWidth;
					_resizeToRightButton.y = ( s.contentHeight - _resizeToRightButton.contentHeight ) / 2;
				}
			}		
			
			if ( s.x >= _hsp )
			{
				if ( hovered || s.indicator )
				{
					s.label.x = 8 + aE.contentWidth + 2;
				}
				else
				{
					s.label.x = 8;
				}
			}
			else
			{
				if ( hovered || s.indicator )
				{
					s.label.x = _hsp - s.x + aE.contentWidth + 2;
				}
				else
				{
					s.label.x = _hsp - s.x;
				}
			}	
			
			var lW : Number = s.contentWidth - s.label.x;
			
			s.label.visible = ( ( s.contentWidth + s.x - _hsp ) > VisualSample.minWidth ) && ( lW > 0 );
			
		    if ( s.label.visible )
			{
				s.label.width = lW;	
			}	
			
			if ( hovered || s.indicator )
			{
				if ( s.label.visible )
				{
					if ( s.y >= _vsp )
					{
						aE.y = 5;
					}
					else
					{
						aE.y = _vsp - s.y;
					}	
					
					if ( s.x >= _hsp )
					{
						aE.x = 8;
					}
					else
					{
						aE.x = _hsp - s.x;
					}	
				}
				else
				{
					if ( s.x >= _hsp )
					{
						aE.x = ( s.contentWidth - aE.contentWidth ) / 2;
					}
					else
					{
						aE.x = _hsp - s.x;
					}
					
					if ( s.y >= _vsp )
					{
						aE.y = 0;
					}
					else
					{
						aE.y = _vsp - s.y;
					}
				}
				
                if ( _hsp > 0 )
				{
					aE.visible = ( ( s.x + s.contentWidth - _hsp ) > aE.contentWidth ) &&
						( ( s.y + s.contentHeight - _vsp ) > aE.contentHeight );
				}
				else aE.visible = true;
			}	
			
			if ( s.label.visible )
			{
				if ( s.y >= _vsp )
				{
					s.label.y = 3;
					s.label.height = s.contentHeight - s.label.y;
				}
				else
				{
					s.label.y = _vsp - s.y;
					s.label.height = s.contentHeight - s.label.y;
				}
				
		        s.label.visible = s.label.height > VisualSample.textMinHeight;
			}
		}	
		
		private function sampleIsVisible( s : BaseVisualSample ) : Boolean
		{
			return scrollRect.intersects( new Rectangle( s.x, s.y, s.contentWidth, s.contentHeight ) );
		}	
		
		/**
		 * Возвращает список семплов видимых в настоящий момент на экране 
		 * @return 
		 * 
		 */		
		private function getVisibleSamples() : Vector.<BaseVisualSample>
		{
			if ( numChildren > 0 )
			{
				var i      : int = 0;
				var result : Vector.<BaseVisualSample> = new Vector.<BaseVisualSample>();
				
				while( i < numChildren )
				{
					var s : BaseVisualSample = getChildAt( i ) as BaseVisualSample;
					
					if ( s )
					{
						s.visible = sampleIsVisible( s );
						
						if ( s.visible )
						{
							result.push( s );
						}
					}
					
					i ++;
				}
			}
			
			return result && result.length > 0 ? result : null;
		}
		
		private function attachElementsTo( s : VisualSample ) : void
		{
			if ( ! _actionButton.parent )
			{
				if ( ! s.loading && ! s.error )
				{
					_actionButton.source = s;
					s.addChild( _actionButton );
				}
			}	
				
			if ( ! _resizeToLeftButton.parent )
			{
				s.addChild( _resizeToLeftButton );	
			}
			
			if ( ! _resizeToRightButton.parent )
			{
				s.addChild( _resizeToRightButton );
			}
		}
		
		private function removeElements() : void
		{
				if ( _actionButton.parent )
				{
					_actionButton.parent.removeChild( _actionButton );
				}	
				
				if ( _resizeToLeftButton.parent )
				{
					_resizeToLeftButton.parent.removeChild( _resizeToLeftButton );
				}	
				
				if ( _resizeToRightButton.parent )
				{
					_resizeToRightButton.parent.removeChild( _resizeToRightButton );
				}
		}	
		
		private function showToolTip( vs : VisualSample, x : Number, y : Number ) : void
		{
			if ( ! _currentMenu && ( vs.contentWidth < VisualSample.widthForToolTip ) )
			{
				vs.toolTip = ToolTipManager.createToolTip( vs.description.name, x + 8.0, y + 14.0 );
				vs.addEventListener( MouseEvent.MOUSE_MOVE, onVisualSampleMouseMove );
			}
		}
		
		private function hideToolTip( vs : VisualSample ) : void
		{
			if ( vs.toolTip )
			{
				vs.removeEventListener( MouseEvent.MOUSE_MOVE, onVisualSampleMouseMove );
				
				ToolTipManager.destroyToolTip( vs.toolTip );
				vs.toolTip = null;
			}
		}
		
		private function onVisualSampleMouseMove( e : MouseEvent ) : void
		{
			var vs : VisualSample = VisualSample( e.currentTarget );
			vs.toolTip.x = e.stageX + 8.0;
			vs.toolTip.y = e.stageY + 14.0;
		}
		
		private function onVisualSampleRollOver( e : MouseEvent ) : void
		{
			if ( e.buttonDown )
			{
				return;
			}
			
			if ( _currentAction <= NONE )
			{
				var vs : VisualSample = VisualSample( e.currentTarget );
				setRollOverVisualSampleState( vs );
				showToolTip( vs, e.stageX, e.stageY );
				setChildIndex( vs, numChildren - 1 );
			}
		}
		
		private function setRollOverVisualSampleState( vs : VisualSample ) : void
		{
			vs.hovered = true;
			
			_resizeToLeftButton.visible = true;
			_resizeToRightButton.visible = true;
			_actionButton.visible = true;
			
			removeElements();
			attachElementsTo( vs );	
			
			orderVisualSampleElements( vs, false, false );
		}
		
		private function onVisualSampleRollOut( e : MouseEvent ) : void
		{
			if ( e.buttonDown )
			{
				return
			}
			
			var vs : VisualSample = VisualSample( e.currentTarget );
			    vs.hovered = false;
			
			hideToolTip( vs );	
				
			if ( _currentAction <= NONE )
			{
				_resizeToLeftButton.visible = false;
				_resizeToRightButton.visible = false;
				_actionButton.visible = false;
				removeElements();
				orderVisualSampleElements( vs, true );
			}
		}
		
		private function onVisualSampleActionButtonRollOver( e : MouseEvent ) : void
		{
			_resizeToLeftButton.visible = false;
			_resizeToRightButton.visible = false;
		}
		
		private function onVisualSampleActionButtonRollOut( e : MouseEvent ) : void
		{
			_resizeToLeftButton.visible = true;
			_resizeToRightButton.visible = true;
		}
		
		private function onErrorButtonClick( e : MouseEvent ) : void
		{
			_currentMenu = SampleMenu.getErrorMenu( DisplayObjectContainer( FlexGlobals.topLevelApplication ), e.currentTarget );
			_currentMenu.addEventListener( MenuEvent.ITEM_CLICK, onVisualSampleErrorMenuClick );
			_currentMenu.addEventListener( MenuEvent.MENU_HIDE, onVisualSampleErrorMenuHide );
			
			_currentMenu.show( e.stageX, e.stageY );	
		}
		
		private function onVisualSampleErrorMenuClick( e : MenuEvent ) : void
		{
			var vs : VisualSample = VisualSample( e.item.source );
			
			if ( e.item.id == SampleMenu.RELOAD )
			{
				var sd : PaletteSample = _palette.getSample( vs.description.id );
				
				if ( sd && ! sd.ready )
				{
					//Если для этого загрузчика уже установлены слушатели, то не ставим их
					var samples : Vector.<BaseVisualSample> = getSampleById( sd.description.id );
					var setListeners : Boolean;
					
					if ( samples )
					{
						for each( var s : BaseVisualSample in samples )
						{
							if ( VisualSample( s ).loading )
							{
								setListeners = true;
								break;
							}
						}
					}
					else
					{
						setListeners = true;
					}
					
					sd = _palette.add( sd.description );
					
					if ( setListeners )
					{
						setLoaderListeners( sd.loader );
					}
					
					vs.loading = true;
					vs.touch();
					orderVisualSampleElements( vs );
				}
			}
		}
		
		private function onVisualSampleErrorMenuHide( e : MenuEvent ) : void
		{
			_currentMenu.removeEventListener( MenuEvent.ITEM_CLICK, onVisualSampleErrorMenuClick );
			_currentMenu.removeEventListener( MenuEvent.MENU_HIDE, onVisualSampleErrorMenuHide );
			_currentMenu = null;
		}
		
		private function onVisualSampleActionButtonClick( e : MouseEvent ) : void
		{
		  var source : BaseVisualSample = e.currentTarget as ActionButton ? ActionButton( e.currentTarget ).source : BaseVisualSample( e.currentTarget );
			
		  _currentMenu = SampleMenu.getSampleMenu( DisplayObjectContainer( FlexGlobals.topLevelApplication ), source );
		  _currentMenu.addEventListener( MenuEvent.ITEM_CLICK, onVisualSampleMenuClick );
		  _currentMenu.addEventListener( MenuEvent.MENU_HIDE, onVisualSampleMenuHide );
		  
		  _currentMenu.show( e.stageX, e.stageY );
		}
		
		private function onVisualSampleMenuClick( e : MenuEvent ) : void
		{
			var source : VisualSample = VisualSample( e.item.source );
			
			if ( e.item.id == SampleMenu.DELETE )
			{
				/*history*/
				addActionToHistoryRemoveSamples( Vector.<BaseVisualSample>( [ source ] ) );
				
				deleteSamples( Vector.<BaseVisualSample>( [ source ] ) );
				
				return;
			}
			
			if ( e.item.id == SampleMenu.COPY )
			{
				copySamples( Vector.<BaseVisualSample>( [ source ] ) );
				
				return;
			}
			
			if ( e.item.id == SampleMenu.CUT )
			{
				/*history*/
				addActionToHistoryRemoveSamples( Vector.<BaseVisualSample>( [ source ] ) );
				
				cutSamples( Vector.<BaseVisualSample>( [ source ] ) );
				
				return;
			}	
			
			if ( e.item.id == SampleMenu.INVERT )
			{
				invertSamples( Vector.<BaseVisualSample>( [ source ] ) );
				addActionToHistoryInvert( Vector.<BaseVisualSample>( [ source ] ) );
				
				return;
			}
			
			if ( e.item.id == SampleMenu.LOOP )
			{
				automaticTuneOnOffSamples( Vector.<BaseVisualSample>( [ source ] ) );
				addActionToHistoryAutomaticTuneOnOffSamples( Vector.<BaseVisualSample>( [ source ] ) );
				
				return;
			}	
		}
		
		private function onVisualSampleMenuHide( e : MenuEvent ) : void
		{
			_currentMenu.removeEventListener( MenuEvent.ITEM_CLICK, onVisualSampleMenuClick );
			_currentMenu.removeEventListener( MenuEvent.MENU_HIDE, onVisualSampleMenuHide );
			_currentMenu = null;
		}	
		
		override public function updateScrollRect():void
		{
			super.updateScrollRect();
			orderVisibleSamples();
		}
		
		/**
		 * Если во время перетаскивания семплы не удалось разместить, то запускаем анимацию возврата их 
		 * обратно 
		 * 
		 */		
		private function undoDragging() : void
		{
			_tween = new Tween( this, 0, _draggingUndoTime, _draggingUndoTime );
		}	
		
		mx_internal function onTweenUpdate(value:Number):void
		{
			var i : int = 0;
			
			while( i < _activeSamples.length )
			{
				var s     : BaseVisualSample      = _activeSamples[ i ];
				var saved : InitialSamplePosition = _initialPositions[ i ];
				
				var startX : Number = s.position / _scale;
				var endX   : Number = saved.position / _scale;
				var startY : Number = s.trackNumber * _trackHeight;
				var endY   : Number = saved.trackNumber * _trackHeight;
				
				s.x = startX + ( ( endX - startX ) * value ) / _draggingUndoTime;
				s.y = startY + ( ( endY - startY ) * value ) / _draggingUndoTime;
				
				i ++;
			}	
		}
		
		mx_internal function onTweenEnd( value:Number ) : void
		{
			if ( _currentAction == UNDO_DRAGGING )
			{
				draggingTweenEnd();
			}
			else if ( _currentAction == UNDO_CLONING )
			{
				cloningTweenEnd();
			}	
			
			clearDraggingParameters();
			_currentAction = NONE;
		}
		
		private function draggingTweenEnd() : void
		{
			var i : int = 0;
			
			while( i < _activeSamples.length )
			{
				var s     : BaseVisualSample      = _activeSamples[ i ];
				var saved : InitialSamplePosition = _initialPositions[ i ];
				
				//Включаем звучание
				if ( s.note )
				{
					_seq.lockNote( s.note, false );
					s.note.start = saved.position;
					
					//Семпл находится не на виртуальной дорожке
					if ( s.trackNumber < _startNumTracks )
					{
						_seq.removeNoteFrom( s.note, s.trackNumber );
					}	
					
					_seq.addNoteTo( s.note, saved.trackNumber );
				}
				
				s.trackNumber = saved.trackNumber;
				s.position    = saved.position;
				
				orderSample( s );
				s.touch();
				
				var vs : VisualSample = s as VisualSample;
				if ( vs )
				{
					orderVisualSampleElements( vs, true );
				}	
				
				i ++;
			}
		}	
		
		private function cloningTweenEnd() : void
		{
			var i : int = 0;
			
			while( i < _activeSamples.length )
			{
				var s     : BaseVisualSample      = _activeSamples[ i ];
				
				removeSample( s );
				i ++;
			}
		}
		
		/****************Методы для поддержки истории для перемещения по истории событий***********************************************/
		
		private function moveSamples( names : Vector.<String>, posOffset : Number, trackOffset : int ) : void
		{
			for each( var name : String in names )
			{	
				var s               : BaseVisualSample = BaseVisualSample( getChildByName( name ) );
				var newPos          : Number = s.position + posOffset;
				var newTrackNumber  : int = s.trackNumber + trackOffset;
				
				if ( s.note )
				{
					s.note.start = newPos;
					
					if ( trackOffset != 0 )
					{
						_seq.removeNoteFrom( s.note, s.trackNumber );
						_seq.addNoteTo( s.note, newTrackNumber );
					}	
				}	
				
				s.position    = newPos;
				s.trackNumber = newTrackNumber;
				
				afterAction( s );
			}
		}
		
		private function resizeLeftSample( sampleName : String, offset : Number ) : void
		{
			var s : BaseVisualSample = BaseVisualSample( getChildByName( sampleName ) );
			var dOffset : Number = s.offset - offset;
			
			s.offset    = offset;
			s.position -= dOffset;
			s.duration += dOffset;
			
			if ( s.note )
			{
				s.note.start = s.position;
		        
				var loop : AudioLoop = s.note.source as AudioLoop;
				
				if ( loop )
				{
					loop.offset = s.offset;
					loop.length = s.duration;
				}	
			}	
			
			afterAction( s );
		}
		
		private function resizeRightSample( sampleName : String, duration : Number ) : void
		{
			var s : BaseVisualSample = BaseVisualSample( getChildByName( sampleName ) );
			
			s.duration = duration;
			
			if ( s.note )
			{
				AudioLoop( s.note.source ).length = s.duration;
			}
			
			afterAction( s );
		}
		
		/**
		 * ПРеобразует список семплов в список уникальных имен семплов 
		 * @param samples
		 * @return 
		 * 
		 */		
		private function sampleListToSampleNames( samples : Vector.<BaseVisualSample> ) : Vector.<String>
		{	
			var names : Vector.<String> = new Vector.<String>( samples.length );
			var i : int = 0;
			
			while( i < samples.length )
			{
				names[ i ] = samples[ i ].name;
				
				i ++;
			}
			
			return names;
		}
		
		/**
		 * Преобразует список уникальных имен семплов в список семплов 
		 * @param names
		 * @return 
		 * 
		 */		
		private function sampleNamesToSampleList( names : Vector.<String> ) : Vector.<BaseVisualSample>
		{
			var samples : Vector.<BaseVisualSample> = new Vector.<BaseVisualSample>( names.length );
			var i       : int = 0;
			
			while( i < names.length )
			{
				samples[ i ] = BaseVisualSample( getChildByName( names[ i ] ) );
				
				i ++;
			}
			
			return samples;
		}	
		
		private function invertSamplesByNames( names : Vector.<String> ) : void
		{
			invertSamples( sampleNamesToSampleList( names ) );
		}
		
		private function automaticTuneOnOffSamplesByNames( names : Vector.<String> ) : void
		{
			automaticTuneOnOffSamples( sampleNamesToSampleList( names ) );
		}	
		
		/******************************************************************************************************************************/
		
	}	
}




import components.sequencer.clipboard.SampleClipboardRecord;
import components.sequencer.timeline.visual_sample.BaseVisualSample;

/**
 * 
 * Класс для хранения стартового положения группы семплов во время перетаскивания
 * 
 */	

class InitialSamplePosition
{
	public var position     : int;
	public var trackNumber  : int;
	public var trackSamples : Vector.<BaseVisualSample>;
	
	public function InitialSamplePosition( position : Number, trackNumber : int, trackSamples : Vector.<BaseVisualSample> = null )
	{
		this.position     = position;
		this.trackNumber  = trackNumber;
		this.trackSamples = trackSamples;
	}
}



/**
 *  
 * Вспомогательная структура описывающая ключевые объекты в группе семплов скопированных в буфер обмена
 * 
 */	
class KeyRecords
{
	public var left   : SampleClipboardRecord;
	public var right  : SampleClipboardRecord;
	public var top    : SampleClipboardRecord;
	public var bottom : SampleClipboardRecord;
	
	public function KeyRecords( initObject : SampleClipboardRecord )
	{
		left   = initObject;
		right  = initObject;
		top    = initObject;
		bottom = initObject;
	}	
}