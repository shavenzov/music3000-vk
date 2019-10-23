package components.sequencer.controls.navigatorClasses
{
	import classes.Sequencer;
	import classes.SequencerImplementation;
	
	import com.audioengine.sequencer.Note;
	import com.audioengine.sequencer.events.SequencerEvent;
	
	import components.sequencer.ColorPalette;
	import components.sequencer.timeline.TimeLineParameters;
	
	import flash.events.Event;
	
	import mx.core.UIComponent;
	
	public class SamplesView extends UIComponent
	{
		/**
		 * Размер одной дорожки 
		 */		
		private static const TRACK_HEIGHT : Number = 3.0;
		
		protected var _seq : SequencerImplementation;
		
		/**
		 * Переменная для отслеживания изменений в количестве дорожек 
		 */		
		private var _numTracks : int = 0;
		
		/**
		 * Дорожки на заднем фоне 
		 */		
		//private var tracks : TracksView;
		private var lastW  : Number;
		
		public function SamplesView()
		{
			super();
			_seq = classes.Sequencer.impl;
			
			addEventListener( Event.ADDED_TO_STAGE, onAddedToStage );
			addEventListener( Event.REMOVED_FROM_STAGE, onRemovedFromStage );
		}
		
		private function onAddedToStage( e : Event ) : void
		{
			_seq.addEventListener( SequencerEvent.SAMPLE_CHANGE, onSomethingChanged );
			_seq.addEventListener( SequencerEvent.POSITION_CHANGED, onSomethingChanged );
		}
		
		private function onRemovedFromStage( e : Event ) : void
		{
			_seq.removeEventListener( SequencerEvent.SAMPLE_CHANGE, onSomethingChanged );
			_seq.removeEventListener( SequencerEvent.POSITION_CHANGED, onSomethingChanged );
		}
		
		private function onSomethingChanged( e : SequencerEvent ) : void
		{
			invalidateDisplayList();
			invalidateProperties();
		}
		
		override protected function measure():void
		{	
			super.measure();
			
			measuredHeight = TimeLineParameters.MAX_NUM_TRACKS * TRACK_HEIGHT;
		}
		
		override protected function createChildren() : void
		{
			super.createChildren();
			
			/*tracks = new TracksView();
			addChild( tracks );*/
		}	
		
		private function drawNote( track : int, w : Number, note : Note ) : void
		{	
			var pos    : Number = ( note.start * w ) / _seq.duration;
			var length : Number = ( note.length * w ) / _seq.duration;
			
			graphics.beginFill( ColorPalette.getColor( track ), 0.85 );
			graphics.drawRect( pos, track * TRACK_HEIGHT, length, TRACK_HEIGHT );
			graphics.endFill();
		}
		
		private function drawPlayHead( w : Number, h : Number ) : void
		{
			var pos : Number = ( _seq.position * w ) / _seq.duration;
			pos ++;
			graphics.lineStyle( 2.0, 0xD1AE0F, 1.0 );
			graphics.moveTo( pos, 0 );
			graphics.lineTo( pos, h ); 
		}
		
		override protected function updateDisplayList( w  :Number, h : Number ):void
		{
			super.updateDisplayList( w, h );
			
			if ( ( lastW != w ) || ( _numTracks != _seq.numChannels ) )
			{
				_numTracks = _seq.numChannels;
				//tracks.draw( w, _numTracks, TRACK_HEIGHT );
				lastW = w;
			}	
			
			graphics.clear();
			
			graphics.beginFill( 0x333333, 0.5 );
			graphics.drawRect( 0, 0, unscaledWidth, unscaledHeight );
			graphics.endFill();
			
			var i : int = 0;
			
			graphics.lineStyle( 1.0, 0x808080, 0.5 );
			
			while( i < _seq.numChannels )
			{
				var notes : Vector.<Note> = _seq.getChannelAt( i ).listNote.notes;
				
				for each( var note : Note in notes )
				{
					drawNote( i, w, note );
				}
				
				i ++;
			}
			
			 drawPlayHead( w, h );
		}	
	}
}