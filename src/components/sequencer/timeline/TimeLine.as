package components.sequencer.timeline
{
	import com.audioengine.core.AudioData;
	
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	import mx.core.DragSource;
	import mx.core.UIComponent;
	import mx.events.DragEvent;
	import mx.events.PropertyChangeEvent;
	import mx.events.ResizeEvent;
	import mx.managers.DragManager;
	import mx.managers.history.History;
	import mx.managers.history.HistoryOperation;
	import mx.managers.history.HistoryRecord;
	
	import spark.core.IViewport;
	
	import classes.BaseDescription;
	import classes.SequencerImplementation;
	
	import components.sequencer.clipboard.SampleClipboardRecord;
	import components.sequencer.timeline.events.MarkerChangeEvent;
	import components.sequencer.timeline.events.MarkerEvent;
	import components.sequencer.timeline.events.SelectionSampleEvent;
	import components.sequencer.timeline.events.TracingEvent;
	import components.sequencer.timeline.events.TrackerEvent;
	import components.sequencer.timeline.visual_sample.BaseVisualSample;
	
	public class TimeLine extends UIComponent implements IScale, IPosition, IViewport
	{
		/**
		 * Смещение инициирующее процесс выделения семплов
		 */
		private static const START_SELECTION_OFFSET : Number = 3.0;
		
		/**
		 * Смещение инициирующее процесс создания области "Зацикливания" 
		 */		
	    private static const START_LOOP_OFFSET : Number = 8.0;
		
		/**
		 * Координаты стартовой точки выделения
		 */
		private var _selectionStartPos : Point;
		/**
		 * Идет процесс установки границы петли 
		 */		
		private var _loopDragging : Boolean;
		
		/**
		 * Как отображать значения на рулетке
		 * MeasureType.MEASURES - в тактах
		 * MeasureType.SECONDS  - в секундах  
		 */		
		private var _viewType : int = MeasureType.SECONDS;
		private var _viewTypeChanged : Boolean;
		
		/**
		 * Как отображать сетку
		 * MeasureType.MEASURES - в тактах
		 * MeasureType.SECONDS  - в секундах 
		 */		
		private var _measureType : int = MeasureType.MEASURES;
		private var _measureTypeChanged : Boolean;
		
		/**
		 * Скорость воспроизведения ( ударов в минуту ) 
		 */		
		private var _bpm : Number;
		private var _bpmChanged : Boolean;
		
		/**
		 * Отображать ли маркеры "петли" 
		 */
		private var _loopMarkers : Boolean;
		private var _loopMarkersChanged : Boolean;
		
		/**
		 * Шаг засечек в фреймах в масштабе 1:1 
		 */		
		private var _division : Number = AudioData.RATE;
		
		/**
		 * Минимальное расстояние между засечками 
		 */		
		private var _divisionMinStep : Number = 40;
		
		/**
		 * Цвет засечек 
		 */		
		private var _divisionColor : uint = 0xFFFFFF;
		
		/**
		 * Толщина засечек 
		 */		
		private var _divisionWeight : Number = 0.1;
		
		/**
		 * Прозрачность засечек 
		 */		
		private var _divisionAlpha : Number = 0.5;
		
		/**
		 * Высота каждой из дорожек 
		 */		
		private var _trackHeight : Number = Settings.TRACK_HEIGHT;
		
		/**
		 * Количество отображаемых дорожек 
		 */		
		private var _numTracks        : int = 0;
		private var _numTracksChanged : Boolean;
		
		/**
		 * Горизонтальная сетка 
		 */		
		private var _hg : HGrid;
		
		/**
		 * Вертикальная сетка 
		 */		
		private var _vg : VGrid;
		
		/**
		 * Слой для выделения семплов "растягиванием рамочки" 
		 */		
		private var _rectSelection : RectSelection;
		
		/**
		 * Рулетка (прокручивается)
		 */			
		private var _ruller : Ruller;	
		
		/**
		 * Список треков (прокручивается)
		 */		
		private var _tracks : Tracker;
		
		/**
		 * Список маркеров (прокручивается) 
		 */		
		public var _markers : Markers;
		
		/**
		 * Прозрачный задний фон, для удачной работы DragManager 
		 */		
		private var empty_bg : Shape;
		
		/**
		 *Масштаб Количество секунд в пикселе
		 *Это значение используется для определения длины трека по умолчанию на основании _duration 
		 */
		private var _scale       : Number = 100.0;
		private var _scaleChanged : Boolean = true;
		
		/**
		 *Длина объекта в секундах 
		 * 
		 */
		private var _duration        : Number = 3 * AudioData.RATE;
		private var _durationChanged : Boolean = true;
		
		/**
		 * При изменении размера
		 */		
		private var _sizeChanged : Boolean;
		
		/**
		 * Ссылка на секвенсор 
		 */		
		private var _seq : classes.SequencerImplementation;
		
		/**
		 * Прокрутка в пограничных областях 
		 * 
		 */
		public var _tracing : Boolean;
		
		/**
		 * Событие инициировавшее слежение 
		 */
		private var _tracingEventInitiator : TracingEvent;
		
		/**
		 * Идентификатор таймера 
		 */		
		private var _timerId : int = -1;
		/**
		 * Коэффициент ускорения 
		 */		
		private var _accX : Number = 0.15;
		private var _accY : Number = 0.35;
		
		/**
		 * Текущее смещение по осям 
		 */		
		private var dX : Number = 0;
		private var dY : Number = 0;
		
		private var _lastScrollEvent : MouseEvent;
		
		/**
		 * Для определения момента клика на петле 
		 */		
		private var _lastLoopPosition : Number;
		
		
		
		/**
		 * Идет процесс вставки семпла из библиотеки 
		 * 
		 */
		private var _draggingOperation : Boolean;
		/**
		 * Сколько дорожек показывать во время вставки семпла из библиотеки 
		 */		
		private var _lastNumTracks : int;
		
		public function TimeLine()
		{
			super();
			focusEnabled = false;
			tabEnabled = false;
			
			_seq     = classes.Sequencer.impl;
			
			//Ударов в минуту по умолчанию, в дальнейшем это значение не будет меняться
			bpm = Settings.DEFAULT_PROJECT_BPM;
		}
		
		public function get numSamples() : int
		{
		  return _tracks.numSamples;
		}	
		
		private function startTracing( e : TracingEvent ) : void
		{
			if ( ! _tracing )
			{
				stage.addEventListener( MouseEvent.MOUSE_MOVE, onScrollStageMouseMove, false, 1000 );
				_tracingEventInitiator = e;
				_tracing = true;
			}
			else throw new Error( 'Tracing have already started.' );
		}
		
		private function stopTracing( e : TracingEvent ) : void
		{
			if ( _tracing )
			{
				stage.removeEventListener( MouseEvent.MOUSE_MOVE, onScrollStageMouseMove );
				stopMoving();
				_tracingEventInitiator = null;
				_tracing = false;
			}
			else throw new Error( 'Tracing have already stopped.' );
		}	
		
		private function onScrollStageMouseMove( e : MouseEvent ) : void
		{
			//Если это событие само-сгенерированное, то не обрабатываем его
			if ( e.relatedObject == this )
			{
				return;
			}	
			
			var localPos : Point = _vg.globalToLocal( new Point( e.stageX, e.stageY ) );
			
			//По горизонтали справа
			if ( _tracingEventInitiator.xAxis )
			{
				if ( ( localPos.x > width - TimeLineParameters.AUTO_SCROLL_AREA_X ) &&
					( horizontalScrollPosition < contentWidth - width )
				)
				{	
					dX = localPos.x - ( width - TimeLineParameters.AUTO_SCROLL_AREA_X );
				}
				else //По горизонтали слева
					if ( ( localPos.x < TimeLineParameters.AUTO_SCROLL_AREA_X ) && ( horizontalScrollPosition > 0 ) )
					{
						dX = localPos.x - TimeLineParameters.AUTO_SCROLL_AREA_X;
					}
					else
					{
						dX = 0;
					}
			}	
			
			//По вертикали снизу
			if ( _tracingEventInitiator.yAxis )
			{
				if ( ( localPos.y > height - TimeLineParameters.AUTO_SCROLL_AREA_BOTTOM ) &&
					( verticalScrollPosition < contentHeight - height )
				)
				{
					dY = localPos.y - ( height - TimeLineParameters.AUTO_SCROLL_AREA_BOTTOM );
				}
				else //По вертикали сверху
					if ( ( localPos.y < TimeLineParameters.AUTO_SCROLL_AREA_TOP ) && ( verticalScrollPosition > 0 ) )
					{
						dY = localPos.y - TimeLineParameters.AUTO_SCROLL_AREA_TOP;
					}
					else
					{
						dY = 0;
					}
			}	
			
			 if ( ( dX != 0.0 ) || ( dY != 0.0 ) )
			 {
				 e.stopImmediatePropagation(); 
				 
				 if ( _tracingEventInitiator.gapThenMoving )
				 {
					 _lastScrollEvent = new MouseEvent( e.type, e.bubbles, e.cancelable,
						 e.stageX - dX, e.stageY - dY, this ); 
				 }	 
				 else
				 {
					 _lastScrollEvent = new MouseEvent( e.type, e.bubbles, e.cancelable,
						 e.stageX, e.stageY, this ); 
				 }	 
				 
				 
				 dX *= _accX;
				 dY *= _accY;
				 
				 startMoving();
			 }
			 else
			 {
				 stopMoving();
			 }
		}
		
		private function startMoving() : void
		{
			if ( _timerId == -1 )
			{
				_timerId = setInterval( moving, 50.0 );
				
				//Информируем объект инициировавший слежку о начале перемещения
				if ( _tracingEventInitiator.notify )
				{
					_tracingEventInitiator.currentTarget.dispatchEvent( new TracingEvent( TracingEvent.START_MOVING ) );
				}	
			}
		}
		
		private function stopMoving() : void
		{
			if ( _timerId != -1 )
			{
				clearInterval( _timerId );
				_timerId = -1;
				dX = 0;
				dY = 0;
				
				//Информируем объект инициировавший слежку о завершении перемещения
				if ( _tracingEventInitiator.notify )
				{
					_tracingEventInitiator.currentTarget.dispatchEvent( new TracingEvent( TracingEvent.STOP_MOVING ) );
				}
			}	
		}	
		
		private function moving() : void
		{
			horizontalScrollPosition += dX;
			verticalScrollPosition += dY;
			
			stage.dispatchEvent( _lastScrollEvent );
		}	
		
		public function copySelectedSamples() : void{
			_tracks.copySelectedSamples();
		}
		
		public function pasteFromClipboard( position : Number = -1 ) : void{
			
			if ( position == -1 )
			{
				_tracks.pasteFromClipboard( _markers._playHead.position );
			}
			else
			{
				_tracks.pasteFromClipboard( position );
			}
		}
		
		public function cutSelectedSamples() : void
		{
			_tracks.cutSelectedSamples();
		}
		
		public function selectAllSamples() : void
		{
			_tracks.selectAllSamples();
		}
		
		public function deleteSelectedSamples() : void
		{
			_tracks.deleteSelectedSamples();
		}
		
		public function invertSelectedSamples() : void
		{
			_tracks.invertSelectedSamples();
		}
		
		public function automaticTuneOnOffSelectedSamples() : void
		{
			_tracks.automaticTuneOnOffSelectedSamples();
		}
		
		public function get viewType() : int
		{
			return _viewType;
		}
		
		public function set viewType( value : int ) : void
		{
			if ( value != _viewType )
			{
				_viewType        = value;
				_viewTypeChanged = true;
				
				invalidateProperties();
			}	
		}
		
		public function get measureType() : int
		{
			return _measureType;
		}
		
		public function set measureType( value : int ) : void
		{
			if ( _measureType != value )
			{
				_measureType = value;
				_measureTypeChanged = true;
				
				invalidateProperties();
			}	
		}
		
		public function get bpm() : Number
		{
			return _bpm;
		}
		
		public function set bpm( value : Number ) : void
		{
			if ( bpm != value )
			{
				_bpm = value;
				_bpmChanged = true;
				
				invalidateProperties();
				invalidateDisplayList();
			}	
		}	
		
		public function get position() : Number
		{
			return _markers.position;
		}
		
		public function set position( value : Number ) : void
		{
			_markers.position = value;
		}
		
		public function get leftLoopPosition() : Number
		{
			return _markers.leftLoopPosition;
		}
		
		public function set leftLoopPosition( value : Number ) : void
		{
			_markers.leftLoopPosition = value;
			invalidateProperties();
		}
		
		public function get rightLoopPosition() : Number
		{
			return _markers.rightLoopPosition;
		}
		
		public function set rightLoopPosition( value : Number ) : void
		{
			_markers.rightLoopPosition = value;
			invalidateProperties();
		}
		
		public function get loopMarkers() : Boolean
		{
			return _loopMarkers;
		}
		
		public function set loopMarkers( value : Boolean ) : void
		{
			if ( value != _loopMarkers )
			{
				_loopMarkers = value;
				_loopMarkersChanged = true;
				invalidateProperties();
				addLoopOnOffToHistory();
			}	
		}	
		
		public function get scale():Number
		{
			return _scale;
		}
		
		public function set scale(value:Number):void
		{
			if ( _scale != value )
			{  
				_scale = value;
				_scaleChanged = true;
				
				invalidateProperties();
				invalidateDisplayList();
			}
		}
		
		public function get optimizedDuration() : Number
		{
			return _vg.optimizedDuration;
		}	
		
		public function get duration():Number
		{
			return _duration;
		}
		
		public function set duration(value:Number):void
		{
			if ( _duration != value )
			{
				_duration = value;
				_durationChanged = true;
				
				invalidateProperties();
				invalidateDisplayList();
			}	  
		}
		
		/**
		 * Количество отображаемых дорожек 
		 */
		public function get numTracks() : int
		{
			return _numTracks;
		}
		
		/**
		 * Количество выбранных в данный момент семплов 
		 * @return 
		 * 
		 */		
		public function get selectedSamples() : int
		{
			return _tracks.selectedSamples.length;
		}
	
		/**
		 * Создает новый трек 
		 * @param index - позиция в которой вставить трек относительно других треков
		 * по умолчанию -1 - создать новый трек в самом конце
		 * 
		 */		
		public function createTrackAt( index : int ) : void
		{
			_tracks.createTrackAt( index );
			
			_numTracks = _tracks.numTracks;
			_numTracksChanged = true;
			
			invalidateProperties();
			invalidateSize();
			invalidateDisplayList();
		}
		
		/**
		 * Удаляет трек с указанным индексом 
		 * @param index - индекс трека который необходимо удалить
		 * 
		 */		
		public function removeTrackAt( index : int ) : void
		{
			_tracks.removeTrackAt( index );
			
			_numTracks = _tracks.numTracks;
			_numTracksChanged = true;
			
			invalidateSize();
			invalidateProperties();
			invalidateDisplayList();
		}	
		
		/**
		 * При изменеии положения курсора воспроизведения трекером 
		 * @param e
		 * 
		 */		
		private function onCatchPlayheadPostionChangedFromTracker( e : MarkerChangeEvent ) : void
		{
			dispatchEvent( e );	
		}	
		
		override protected function createChildren():void
		{
			empty_bg = new Shape();
			empty_bg.graphics.beginFill( 0xFFFFFF, 0.0 );
			empty_bg.graphics.drawRect( 0, 0, 10 ,10 );
			empty_bg.graphics.endFill();
			empty_bg.cacheAsBitmap = true;
			
			_vg = new VGrid();
			_vg._division       = _division;
			_vg._divisionWeight = _divisionWeight;
			_vg._divisionAlpha  = _divisionAlpha;
			_vg._divisionColor  = _divisionColor;
			_vg.scale           = _scale;
			_vg.duration        = _duration;
			
			_hg = new HGrid();
			_hg._divisionWeight = _divisionWeight;
			_hg._divisionAlpha  = _divisionAlpha;
			_hg._divisionColor  = _divisionColor;
			_hg._trackHeight    = _trackHeight;
			_hg.numTracks       = _numTracks;
			
			_ruller = new Ruller();
			_ruller._division        = _division;
			_ruller._divisionMinStep = _divisionMinStep;
			_ruller._divisionWeight  = _divisionWeight;
			_ruller.scale            = _scale;
			_ruller.duration         = _duration;
			_ruller.addEventListener( MouseEvent.MOUSE_DOWN, onRullerMouseDown );
			
			_tracks = new Tracker();
			_tracks._division        = _division;
			_tracks._trackHeight     = _trackHeight;
			_tracks.scale            = _scale;
			_tracks.duration         = _duration;
			_tracks.addEventListener( TracingEvent.START_TRACING, startTracing );
			_tracks.addEventListener( TracingEvent.STOP_TRACING, stopTracing );
			_tracks.addEventListener( MarkerChangeEvent.PLAYHEAD_POSITION_CHANGED, onCatchPlayheadPostionChangedFromTracker );
			_tracks.addEventListener( TrackerEvent.START_SAMPLE_DRAGGING, onStartSampleDragging );
			_tracks.addEventListener( TrackerEvent.VIRTUAL_NUM_TRACKS_CHANGED, onVirtualNumTracksChanged );
			_tracks.addEventListener( TrackerEvent.STOP_SAMPLE_DRAGGING, onStopSampleDragging );
			_tracks.addEventListener( SelectionSampleEvent.CHANGE, onSelectionChange );
			
			_markers = new Markers();
			_markers.scale = _scale;
			_markers.duration = _duration;
			_markers.addEventListener( TracingEvent.START_TRACING, startTracing );
			_markers.addEventListener( TracingEvent.STOP_TRACING, stopTracing );
			_markers.addEventListener( MarkerEvent.RIGHT_LOOP_BORDER_PRESS, onLoopMarkerPress );
			_markers.addEventListener( MarkerEvent.RIGHT_LOOP_BORDER_RELEASE, onLoopMarkerRelease );
			_markers.addEventListener( MarkerEvent.LEFT_LOOP_BORDER_PRESS, onLoopMarkerPress );
			_markers.addEventListener( MarkerEvent.LEFT_LOOP_BORDER_RELEASE, onLoopMarkerRelease );
			_markers.addEventListener( MarkerEvent.LOOP_MARKER_PRESS, onLoopMarkerPress );
			_markers.addEventListener( MarkerEvent.LOOP_MARKER_RELEASE, onLoopMarkerRelease );
			//_markers.addEventListener( MarkerChangeEvent.LOOP_CHANGED_ON, onLoopOnOff );
			_markers.addEventListener( MarkerChangeEvent.LOOP_CHANGED_OFF, onLoopOff );
			_markers.addEventListener( MarkerChangeEvent.LEFT_LOOP_BORDER_POSITION_CHANGED, retranslateMarkersEvents );
			_markers.addEventListener( MarkerChangeEvent.RIGHT_LOOP_BORDER_POSITION_CHANGED, retranslateMarkersEvents );
			
			addChild( empty_bg );
			addChild( _vg );
			addChild( _hg );
			addChild( _tracks );
			addChild( _ruller );
			addChild( _markers );
			
			//Слежка для выделения рамочкой
			addEventListener( TracingEvent.START_TRACING, startTracing );
			addEventListener( TracingEvent.STOP_TRACING, stopTracing );
			
			addEventListener( MouseEvent.MOUSE_DOWN, onMouseDown );
			
			//Ретрансляция событий DragManager
			addEventListener( DragEvent.DRAG_ENTER, onDragEnter );
			addEventListener( DragEvent.DRAG_DROP, onDragDrop ); 
			addEventListener( DragEvent.DRAG_EXIT, onDragExit );
			addEventListener( DragEvent.DRAG_OVER, onDragOver );
			
			DragManager.dispatcher.addEventListener( DragEvent.DRAG_START, onDragStart );
		}	
		
		private function onSelectionChange( e : SelectionSampleEvent ) : void
		{
			dispatchEvent( e );
		}
		
		private function retranslateMarkersEvents( e : MarkerChangeEvent ) : void
		{
			dispatchEvent( e );
		}	
		
		private function addLoopOnOffToHistory() : void
		{
			var op1 : HistoryOperation = new HistoryOperation( this, loopOnAndSetLoopBorder, _markers.leftLoopPosition, _markers.rightLoopPosition );
			var op2 : HistoryOperation = new HistoryOperation( this, loopOff );
			
			if ( _loopMarkers )
			{
				History.add( new HistoryRecord( op2, op1,
					         'Отменить включение режима повторения',
							 'Включить режим повторения' ) );
			}
			else
			{
				History.add( new HistoryRecord( op1, op2,
					'Отменить выключение режима повторения',
					'Отключить режим повторения' ) );
			}
		}
		
		private function onLoopOff( e : MarkerChangeEvent ) : void
		{
			_loopMarkers = _markers.loopMarkers;
			
			if ( e.type == MarkerChangeEvent.LOOP_CHANGED_OFF )
			{
				addLoopOnOffToHistory();
				dispatchEvent( e );
			}	
		}	
		
		private var _lastLoopPos : Point;
		
		private function onLoopMarkerPress( e : Event ) : void
		{
		  _lastLoopPosition = ( e.type == MarkerEvent.RIGHT_LOOP_BORDER_PRESS ) ? _markers.rightLoopPosition : _markers.leftLoopPosition;
		  _lastLoopPos = new Point( _markers.leftLoopPosition, _markers.rightLoopPosition ); 
		}
		
		private function onLoopMarkerRelease( e : Event ) : void
		{
			var pos : Number = ( e.type == MarkerEvent.RIGHT_LOOP_BORDER_RELEASE ) ? _markers.rightLoopPosition : _markers.leftLoopPosition;
			
			if ( pos == _lastLoopPosition )
		    {
			  _markers.xPosition = _markers.mouseX;
			  return;
		    }
			
			//Если курсор воспроизведения уехал за границы петли
			/*if ( ! _markers.isCursorInLoop() )
			{
				jumpToLoopStart();
			}
			*/
			if ( ( _lastLoopPos.x != _markers.leftLoopPosition ) || ( _lastLoopPos.y != _markers.rightLoopPosition ) )
			{
				History.add( new HistoryRecord( new HistoryOperation( this, setLoopBorder, _lastLoopPos.x, _lastLoopPos.y ),
					         new HistoryOperation( this, setLoopBorder, _markers.leftLoopPosition, _markers.rightLoopPosition ),
							 'Отменить изменение области повторения',
							 'Изменить область повторения'
				) );
			}
		}	
		
		private function startDragAndDropOperation() : void
		{
			if ( _numTracks <= TimeLineParameters.MAX_NUM_TRACKS )
			{
				_lastNumTracks = numTracks;
							
				//добавляем несколько дорожек на все свободное пространство
				if ( contentHeight < height )
				{
					_numTracks = Math.floor( Math.min( TimeLineParameters.MAX_NUM_TRACKS, ( height - _ruller.contentHeight ) / _trackHeight ) );
				}	
				else //Добавляем одну дополнительную дорожку
				{
				   _numTracks = Math.min( TimeLineParameters.MAX_NUM_TRACKS, _numTracks + 1 );	
				}	
				
				_tracks.numTracks = _numTracks;
				_hg.showHint = false;
				_tracks.invalidateAndTouch();
				_numTracksChanged = true;
				
				invalidateSize();
				invalidateProperties();
				invalidateDisplayList();
				
				_draggingOperation = true;
			}	
		}
		
		private function stopDragAndDropOperation()  : void
		{
			if ( _numTracks <= TimeLineParameters.MAX_NUM_TRACKS )
			{
				_hg.showHint = true;
				_tracks.numTracks = _lastNumTracks;
				_tracks.invalidateAndTouch();
				
				_numTracks = _lastNumTracks;
				
				_numTracksChanged = true;
				
				invalidateProperties();
				invalidateSize();
				invalidateDisplayList();
				
				_draggingOperation = false;
			}	
		}
		
		private function onStartSampleDragging( e : TrackerEvent ) : void
		{
			_lastNumTracks = _numTracks;
			_draggingOperation = true;
		}
		
		private function onVirtualNumTracksChanged( e : TrackerEvent ) : void
		{
			_numTracks = e.numTracksToShow;
			_tracks.numTracks = _numTracks;
			_hg.showHint = e.numTracksToShow < e.maxNumTracksToShow;
			_tracks.invalidateAndTouch();
			_numTracksChanged = true;
			
			invalidateSize();
			invalidateProperties();
			invalidateDisplayList();
		}
		
		private function onStopSampleDragging( e : TrackerEvent ) : void
		{
			_hg.showHint = true;
			_tracks.numTracks = _lastNumTracks;
			_tracks.invalidateAndTouch();
			
			_numTracks = _lastNumTracks;
			
			_numTracksChanged = true;
			
			invalidateProperties();
			invalidateSize();
			invalidateDisplayList();
			
			_draggingOperation = false;
		}	
		
		private function isDragSourceSample( dragSource : DragSource ) : Boolean
		{
			return dragSource.dataForFormat( 'sample' ) as BaseDescription;
		}	
		
		/**
		 * Запоминаем здесь действие истории записываемое при изменении темпа 
		 */		
		private var changeBPMHistoryRecord : HistoryRecord;
		
		private function onDragStart( e : DragEvent ) : void
		{
			if ( isDragSourceSample( e.dragSource ) )
			{
				if ( _seq.numSamples == 0 )
				{
					var description : BaseDescription = BaseDescription( e.dragSource.dataForFormat( 'sample' ) );
					
					changeBPMHistoryRecord = new HistoryRecord( new HistoryOperation( _seq, _seq.changeBPMTo, _bpm ),
						                                        new HistoryOperation( _seq, _seq.changeBPMTo, description.bpm ) );
					
					_seq.changeBPMTo( description.bpm );
				}		
			}
		}
		
		private function onDragEnter( e : DragEvent ) : void
		{
			if ( isDragSourceSample( e.dragSource ) )
			{
				startDragAndDropOperation();
				_tracks.onDragEnter( e );
				DragManager.acceptDragDrop( this );
			}	
		}
		
		private function onDragDrop( e : DragEvent ) : void
		{
			if ( isDragSourceSample( e.dragSource ) )
			{
				stopDragAndDropOperation();
				
				if ( changeBPMHistoryRecord )
				{
					History.startCatching();
					History.add( changeBPMHistoryRecord );
					
					_tracks.onDragDrop( e );
					
					History.stopCatching();
					
					changeBPMHistoryRecord = null;
				}
				else
				{
					_tracks.onDragDrop( e );
				}
			}	
		}
		
		private function onDragExit( e : DragEvent ) : void
		{
			if ( isDragSourceSample( e.dragSource ) )
			{
				stopDragAndDropOperation();
				_tracks.onDragExit( e );
			}	
		}
		
		private function onDragOver( e  : DragEvent ) : void
		{
			if ( isDragSourceSample( e.dragSource ) )
			{
				_tracks.onDragOver( e );
			}	
		}	
		
		/**
		 * Подсвечивает указанную дорожку или выключает подсвечивание если trackNumber = -1 
		 * @param trackNumber
		 * 
		 */		
		public function highlightTrack( trackNumber : int ) : void
		{
			_hg.highlightTrack( trackNumber );
		}
		
		/**
		 * Выделяет указанную дорожку или отменяет выбор если trackNumber = -1 
		 * @param trackNumber
		 * 
		 */		
		public function selectTrack( trackNumber : int ) : void
		{
			_hg.selectTrack( trackNumber );
			_tracks.clearTrackSelection();
			
			if ( trackNumber != -1 )
			{
				_tracks.selectTrack( trackNumber );	
			}		
		}	
		
		/**
		 * Определяет номер дорожки по координатам курсора и подсвечивает её 
		 * @param e
		 * 
		 */		
		public function highlightCursorPosition( e : MouseEvent ) : void
		{
			_hg.highlightTrack( _tracks.cursorPositionToTrackNumber( _tracks.globalToLocal( new Point( e.stageX, e.stageY ) ).y ) );
		}
		
		/**
		 * Обновляет выделение 
		 * 
		 */		
		public function updateSelection() : void
		{
			_hg.invalidateAndTouchDisplayList();
		}	
		
		/**
		 * Определяет номер дорожки по координатам курсора  
		 * @param e - номер дорожки или -1, если не соответствует ни одной дорожке
		 * 
		 */
		public function getHighlightedTrackNumber( e : MouseEvent ) : int
		{
			if ( e.target == _ruller )
			{
			  return _hg.selectedTrack;	
			}
			
			return _tracks.cursorPositionToTrackNumber( _tracks.globalToLocal( new Point( e.stageX, e.stageY ) ).y );
		}
		
		public function swapTracks( index1 : int, index2 : int ) : void
		{
			_tracks.swapTracks( index1, index2 );
		}
		
		public function moveTracks( from : int, to : int ) : void
		{
			_tracks.moveTracks( from, to );
		}	
		
		private function onMouseDown( e : MouseEvent ) : void
		{
			if ( e.target as HGrid )
			{
				_selectionStartPos = new Point( e.stageX, e.stageY );
				stage.addEventListener( MouseEvent.MOUSE_UP, onStageMouseUp );
				stage.addEventListener( MouseEvent.MOUSE_MOVE, onStageMouseMove );
			}	
		}
		
		private function onStageMouseUp( e : MouseEvent ) : void
		{
			if ( _selectionStartPos ) //Для предотвращения нескольких событий при выходе мыши за границы браузера
			{
				_selectionStartPos = null;
				stage.removeEventListener( MouseEvent.MOUSE_UP, onStageMouseUp );
				stage.removeEventListener( MouseEvent.MOUSE_MOVE, onStageMouseMove );
				
				if ( _rectSelection )
				{
					dispatchEvent( new TracingEvent( TracingEvent.STOP_TRACING ) );
					removeChild( _rectSelection );
					_rectSelection = null;
					
					dispatchEvent( new SelectionSampleEvent( SelectionSampleEvent.CHANGE, _tracks.selectedSamples ) );
				}
				else
				{
					if ( _tracks.selectedSamples.length > 0 )
					{
						_tracks.clearSampleSelection();
						dispatchEvent( new SelectionSampleEvent( SelectionSampleEvent.CHANGE, _tracks.selectedSamples ) );
					}	
				}	
			}	
		}
		
		private function onStageMouseMove( e : MouseEvent ) : void
		{
			if ( _rectSelection )
			{
				if ( _rectSelection.contentWidth == 0 ) return; 
				
				_rectSelection.setRectPoint( _selectionStartPos, _tracks.globalToLocal( new Point( e.stageX, e.stageY ) ) );
		        _tracks.selectSamplesUnderRect( _rectSelection.rect );											 
			}
			else
			{
				if ( ( Math.abs( e.stageX - _selectionStartPos.x ) > START_SELECTION_OFFSET ) ||
				   ( Math.abs( e.stageY - _selectionStartPos.y ) > START_SELECTION_OFFSET ) )
				   {
					   _selectionStartPos = _tracks.globalToLocal( _selectionStartPos );
					   _rectSelection = new RectSelection();
					   addChild( _rectSelection );
					   invalidateDisplayList();
					   
					   dispatchEvent( new TracingEvent( TracingEvent.START_TRACING, true, true, null, false, false ) );
				   }
			}	
		}	
		
		/*for history*/
		/*
		Включить режим "Петли" и установить её границы
		*/
		private function loopOnAndSetLoopBorder( start : Number, end : Number ) : void
		{
			_loopMarkers = true;
			_markers.loopMarkers = true;
			_markers.setLoopRegion( start, end );
			
			//Если курсор воспроизведения уехал за границы петли
			if ( ! _markers.isCursorInLoop() )
			{
				jumpToLoopStart();
			}
			
			dispatchEvent( new MarkerChangeEvent( MarkerChangeEvent.START_LOOP_EDITING, -1.0 ) );
			//dispatchEvent( new MarkerChangeEvent( MarkerChangeEvent.LEFT_LOOP_BORDER_POSITION_CHANGED, start ) );
			//dispatchEvent( new MarkerChangeEvent( MarkerChangeEvent.RIGHT_LOOP_BORDER_POSITION_CHANGED, end ) );
			dispatchEvent( new MarkerChangeEvent( MarkerChangeEvent.END_LOOP_EDITING, -1.0 ) );
		}
		
		/**
		 * Установить границы петли 
		 * @param start
		 * @param end
		 * 
		 */		
		private function setLoopBorder( start : Number, end : Number ) : void
		{
			_markers.setLoopRegion( start, end );
			
			//Если курсор воспроизведения уехал за границы петли
			if ( ! _markers.isCursorInLoop() )
			{
				jumpToLoopStart();
			}
			
			dispatchEvent( new MarkerChangeEvent( MarkerChangeEvent.LEFT_LOOP_BORDER_POSITION_CHANGED, start ) );
			dispatchEvent( new MarkerChangeEvent( MarkerChangeEvent.RIGHT_LOOP_BORDER_POSITION_CHANGED, end ) );
		}
		
		/**
		 * Отключение режима "Петли" 
		 * 
		 */		
		private function loopOff() : void
		{
			_loopMarkers = false;
			_markers.loopMarkers = false;
			dispatchEvent( new MarkerChangeEvent( MarkerChangeEvent.LOOP_CHANGED_OFF, -1 ) );
		}	
		
		private function onRullerMouseDown( e : MouseEvent ) : void
		{
			stage.addEventListener( MouseEvent.MOUSE_MOVE, onRullerMouseMove );
			stage.addEventListener( MouseEvent.MOUSE_UP, onRullerMouseUp );
			_selectionStartPos = new Point( e.stageX, e.stageY );
		}
		
		private function onRullerMouseMove( e : MouseEvent ) : void
		{
		   if ( _loopDragging )
		   {
			   _markers.setXLoopRegion( _selectionStartPos.x, _markers.globalToLocal( new Point( e.stageX, e.stageY ) ).x );
			   return;   
		   }   
		   
		   if ( Math.abs( e.stageX - _selectionStartPos.x ) > START_LOOP_OFFSET )
		   {
			   dispatchEvent( new MarkerChangeEvent( MarkerChangeEvent.START_LOOP_EDITING, -1.0 ) );
			   
			   _loopDragging = true;
			   _loopMarkers = true;
			  _markers.loopMarkers = true;
			  
			  _selectionStartPos = _markers.globalToLocal( _selectionStartPos );
			  _markers.setXLoopRegion( _selectionStartPos.x, _markers.globalToLocal( new Point( e.stageX, e.stageY ) ).x );
			  _markers.touch();
			  
			  startTracing( new TracingEvent( TracingEvent.START_TRACING, true, false ) );
		   }
		}
		
		/**
		 * Перебрасывает курсор воспроизведения, на начало петли 
		 * 
		 */		
		private function jumpToLoopStart() : void
		{	
			/*_markers.position = _seq.inverse ? _markers.rightLoopPosition : _markers.leftLoopPosition;
			_markers.dispatchEvent( new MarkerChangeEvent( MarkerChangeEvent.PLAYHEAD_POSITION_CHANGED, _markers.position ) );*/
		}
		
		private function onRullerMouseUp( e : MouseEvent ) : void
		{
			stage.removeEventListener( MouseEvent.MOUSE_MOVE, onRullerMouseMove );
			stage.removeEventListener( MouseEvent.MOUSE_UP, onRullerMouseUp );
			
			if ( _loopDragging )
			{
				jumpToLoopStart();
				
				dispatchEvent( new MarkerChangeEvent( MarkerChangeEvent.END_LOOP_EDITING, -1.0 ) );
				stopTracing( null );
				
				addLoopOnOffToHistory();
			}
			else
			{
				_markers.xPosition = _markers.globalToLocal( new Point( e.stageX, e.stageY ) ).x;
			}	
			
			_selectionStartPos = null;
			_loopDragging = false;
		}		
		
		override protected function updateDisplayList( w : Number, h : Number ):void
		{ 
			if ( _numTracks == 0 )
			{
				_ruller.visible = false;
				_markers.visible = false;
			}
			else
			{
				_ruller.visible = true;
				_markers.visible = true;
			}
			
			empty_bg.width = w;
			empty_bg.height = h;
			
			//Область прокрутки
			  _tracks.scrollWidth = w;
			  _tracks.scrollHeight = h - _ruller.contentHeight;
			  //_tracks.touch();
			  
			  _ruller.scrollWidth = w;
			  _ruller.scrollHeight = _ruller.contentHeight;
			  //_ruller.touch();
			  
			  if ( _markers.hsp > _markers.offset )
			  {
				  _markers.leftPadding = 0.0;
				  _markers.x = 0.0;
				  _markers.scrollWidth = w;
			  }
			  else
			  {
				  _markers.leftPadding = _markers.offset - _markers.hsp;
				  _markers.x = - _markers.leftPadding;
				  _markers.scrollWidth =  w + _markers.leftPadding;
			  }	  
			  
			  _markers.contentHeight = _tracks.contentHeight + _ruller.contentHeight; 
			  _markers.scrollHeight = _ruller.contentHeight + ( _tracks.scrollHeight > _tracks.contentHeight ? _tracks.contentHeight : _tracks.scrollHeight );
			  _markers.invalidateAndTouch();
			  
			  //Компоновка
			  _tracks.y = _ruller.contentHeight;
			  _hg.y     = _ruller.contentHeight;
			  _hg.contentWidth = w < _tracks.contentWidth ? w : _tracks.contentWidth;
			  //_hg.contentHeight = _tracks.contentHeight;
			  _hg.scrollWidth = w;
			  _hg.scrollHeight = h - _ruller.contentHeight;
			  //_hg.touch();
			  
			  _vg.y = _ruller.contentHeight;
			  _vg.contentHeight = _tracks.contentHeight; 
			  _vg.scrollWidth = w;
			  _vg.scrollHeight = _tracks.contentHeight + _ruller.contentHeight < h ? _tracks.contentHeight : h - _ruller.contentHeight; 
				  
			  _vg.invalidateAndTouch();//!!!
			  
			  if ( _rectSelection )
			  {
				  _rectSelection.y = _tracks.y;
				  _rectSelection.contentWidth = _tracks.contentWidth;
				  _rectSelection.contentHeight = _tracks.contentHeight;
				  _rectSelection.scrollWidth = _tracks.scrollWidth;
				  _rectSelection.scrollHeight = _tracks.scrollHeight;
				  _rectSelection.hsp = _tracks.hsp;
				  _rectSelection.vsp = _tracks.vsp;
				  
				  _rectSelection.updateScrollRect();
			  }  
			  
			  _tracks.updateScrollRect();
		      _ruller.updateScrollRect();
		      _markers.updateScrollRect();
		      _vg.updateScrollRect();
			  _hg.updateScrollRect(); 
		}	
		
		override protected function commitProperties():void
		{		
		  var _contentWidthNeedUpdate  : Boolean;
		  var _contentHeightNeedUpdate : Boolean;
		  var _newHSP                  : Number;  
			
		  if ( _loopMarkersChanged )
		  {
			  _markers.loopMarkers = _loopMarkers;
			  _loopMarkersChanged = false;
		  }  
		  
		  if ( _numTracksChanged )
		  {
			  _hg.numTracks = _numTracks;
			  _numTracksChanged = false;
			  _contentHeightNeedUpdate = true;
		  }   
		  
		  if ( _scaleChanged || _bpmChanged )
		  {
			  _seq.palette.waves.update( _scale, _bpm );
		  }
		  
		  if ( _durationChanged || _scaleChanged )
		  {   
			  _tracks.scale    = _scale;
			  _tracks.duration = _duration; 
			 		  
			  _markers.scale   = _scale;
			  _markers.duration = _duration;
			  
			  _vg.scale = _scale;
			  _vg.duration = _duration;
			 
			  _ruller.scale    = _scale;
			  _ruller.duration = _vg.optimizedDuration;
			  
			  if ( _scaleChanged )
			  {	  
				 if ( contentWidth > 0 )
				 {
					 _newHSP = horizontalScrollPosition * ( _vg.getOptimizedContentWidth( _scale, _duration ) / contentWidth ); 
				 }
				 
				 dispatchEvent( new PropertyChangeEvent( PropertyChangeEvent.PROPERTY_CHANGE, false, false, null, 'scaleChanged', _scale, _scale, this ) );
			  }
			  
			  _durationChanged = false;
			  _scaleChanged = false;
			  _contentWidthNeedUpdate = true;
		  }
		  
		  if ( _bpmChanged || _viewTypeChanged || _measureTypeChanged )
		  {
			  _tracks.bpm = _bpm;
			  _tracks.measureType = _measureType;
			  
			  _ruller.bpm = _bpm;
			  _ruller.measureType = _measureType;
			  _ruller.viewType = _viewType;
			  
			  _vg.bpm = _bpm;
			  _vg.measureType = _measureType;
			  
			  _tracks.invalidateAndTouch();
			  
			  _markers.stickInterval = _tracks.stickInterval;
			  
			  _bpmChanged = false;
			  _viewTypeChanged = false;
			  _measureTypeChanged = false;
		  }	  
		  
		  _hg.touch();
		  _vg.touch();
		  _ruller.touch();
		  _tracks.touch();
		  _markers.touch();
		  
		  if ( ! isNaN( _newHSP ) )
		  {  
			  horizontalScrollPosition = _newHSP;
		  }
		  
		  if ( _contentWidthNeedUpdate || _contentHeightNeedUpdate )
		  {
			  dispatchEvent( new ResizeEvent( ResizeEvent.RESIZE ) );
			  
			  if ( _contentWidthNeedUpdate )
			  {
				  dispatchEvent( new PropertyChangeEvent( PropertyChangeEvent.PROPERTY_CHANGE, false, false, null, "contentWidth" ) ); 
			  }
			  
			  if ( _contentHeightNeedUpdate )
			  {
				  dispatchEvent( new PropertyChangeEvent( PropertyChangeEvent.PROPERTY_CHANGE, false, false, null, "contentHeight" ) );
			  }
		  }
		 
		}	
		
		override protected function measure():void
		{
			measuredWidth  = _vg.contentWidth;
			measuredHeight = _ruller.contentHeight + _tracks.contentHeight;
			
			//Место для надписи, для создания дорожки перетащите семпл сюда
			if ( ( _numTracks != 0 ) && ( _numTracks < TimeLineParameters.MAX_NUM_TRACKS ) )
			{
				measuredHeight += _trackHeight;
			}	
		}
		
		/**
		 * 
		 * Реализация IViewport
		 * 
		 */		
		public function get clipAndEnableScrolling() : Boolean
		{
			return _tracks ? _tracks.clipAndEnableScrolling : false;
		}	
		
		public function set clipAndEnableScrolling( value : Boolean ) : void
		{
			if ( _tracks )
			{
				_tracks.clipAndEnableScrolling = value;
				_ruller.clipAndEnableScrolling = value;
				_hg.clipAndEnableScrolling     = value;	
				_vg.clipAndEnableScrolling     = value;
				
				invalidateDisplayList();
			}
		}
		
		public function get contentHeight() : Number
		{
			if ( _numTracks == 0 ) return 0;
			
			return _hg ? _hg.contentHeight + _ruller.contentHeight : 0;
		}
		
		public function get contentWidth() : Number
		{
			if ( _numTracks == 0 ) return 0;
			
			return _vg ? _vg.contentWidth : 0;
		}
		
		public function get horizontalScrollPosition():Number
		{
		   return _vg ? _vg.hsp : 0;	
		}
		
		public function set horizontalScrollPosition(value:Number):void
		{
			_tracks.hsp = value;
			_ruller.hsp = value;
			_markers.hsp = value;
			_vg.hsp = value;
			
			if ( _rectSelection )
			{
				_rectSelection.hsp = value;
				_tracks.selectSamplesUnderRect( _rectSelection.rect );
			}
			
			dispatchEvent( new PropertyChangeEvent( PropertyChangeEvent.PROPERTY_CHANGE, false, false, null, "horizontalScrollPosition", value, value ) );
			
			invalidateDisplayList();
		}
		
		public function get verticalScrollPosition() : Number
		{
			return _hg ? _hg.vsp : 0;
		}
		
		public function set verticalScrollPosition( value : Number ) : void
		{
			_tracks.vsp = value;
			_hg.vsp = value;
			_vg.vsp = value;
			_markers.vsp = value;
			
			if ( _rectSelection )
			{
				_rectSelection.vsp = value;
				_tracks.selectSamplesUnderRect( _rectSelection.rect );
			}	
			
			dispatchEvent( new PropertyChangeEvent( PropertyChangeEvent.PROPERTY_CHANGE, false, false, null, "verticalScrollPosition", value, value ) );
			
			invalidateDisplayList();
		}
		
		public function getHorizontalScrollPositionDelta( navigationUnit : uint ) : Number
		{
			return 0;
		}
		
		public function getVerticalScrollPositionDelta(navigationUnit:uint):Number
		{
			return 0;
		}
		
		public function get rullerHeight() : Number
		{
			return _ruller ? _ruller.contentHeight : 0;
		}
		
		/**
		 * Создает "пустой" семпл на timeline для записи, в указанную позицию и номер дорожки и возвращает указатель на него
		 * @param pos
		 * @param trackNumber
		 * @return 
		 * 
		 */		
		public function createSampleForRecord( pos : Number, trackNumber : int ) : BaseVisualSample
		{
			return _tracks.createSampleForRecord( pos, trackNumber );
		}
		
		/**
		 * Запускает механизм автоматического обновления семпла при изменении данных источника 
		 * @param s
		 * 
		 */		
		public function startRecordingTo( s : BaseVisualSample ) : void
		{
			_ruller.mouseEnabled = false;
			_markers.mouseEnabled = false;
			_markers.mouseChildren = false;
			_tracks.startRecordingTo( s );
		}
		
		/**
		 * Останавливает механизм автомвтического обновления семпла при изменении данных источника 
		 * @param s
		 * 
		 */		
		public function stopRecordingFrom( s : BaseVisualSample ) : void
		{	
			_tracks.stopRecordingFrom( s );
			_markers.mouseEnabled = true;
			_markers.mouseChildren = true;
			_ruller.mouseEnabled = true;
		}
		
		public function addSamplesByDescriptions( list : Vector.<SampleClipboardRecord> ) : void
		{	
			_tracks.addSamplesByDescriptions( list );
		}
		
		public function clearAll() : void
		{	
			_tracks.clearAll();
		}
		
		public function get showDragAndDropTip() : Boolean
		{
			return _hg.showHint;
		}
		
		public function set showDragAndDropTip( value : Boolean ) : void
		{
			_hg.showHint = value;
			invalidateProperties();
			invalidateDisplayList();
		}
	}
}