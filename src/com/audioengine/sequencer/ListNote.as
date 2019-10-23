package com.audioengine.sequencer
{
	import com.audioengine.core.IAudioData;
	import com.audioengine.sequencer.events.SequencerEvent;
	import com.serialization.IXMLSerializable;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.sampler.Sample;

	public class ListNote extends EventDispatcher implements IXMLSerializable
	{
		private const _notes : Vector.<Note> = new Vector.<Note>();
		
		private var _start : Number = 0.0;
		private var _end   : Number = 0.0;
		
		/**
		 * Скорость воспроизведения 
		 */		
		private var _bpm : Number = 140.0;
		
		/**
		 *  Вкл / Выкл автоматического пересчета _start и _end
		 */		
		private var _calculateLength : Boolean = true;
		
		/**
		 * Определяет игнорировать ли изменения или нет 
		 */		
		private var _ignoreChanges : Boolean;
		
		public function ListNote()
		{
		  super();
		}
		
		public function get notes() : Vector.<Note>
		{
			return _notes;
		}	
		
		public function get bpm() : Number
		{
			return _bpm;
		}
		
		public function set bpm( value : Number ) : void
		{
			//Коэффициент смещения по оси времени
			var k : Number = _bpm / value; 
			var i : int = 0;
			
			_bpm = value;
			
			if ( _notes.length > 0)
			{
				//Изменяем bpm для всех AudioLoop
				_calculateLength = false;
				
				while( i < _notes.length )
				{
					_notes[ i ].start *= k; 
					
					var loop : AudioLoop = _notes[ i ].source as AudioLoop;
					
					if ( loop )
					{
						loop.bpm = _bpm;
					}	
					
					i ++;
				}
				
				_calculateLength = true;
				
				if ( ! _ignoreChanges )
				{
					calculateLength( new SequencerEvent( SequencerEvent.SAMPLE_CHANGE ) );	
				}	
			}
		}	
		
		public function exists( note : Note ) : Boolean
		{
			for each ( var n : Note in _notes )
			{
				if ( n == note )
				 return true;	
			}
			
			return false;
		}
		
		public function get ignoreChanges() : Boolean
		{
			return _ignoreChanges;
		}
		
		public function set ignoreChanges( value : Boolean ) : void
		{
			if ( _ignoreChanges != value )
			{
				_ignoreChanges = value;
				
				for each( var note : Note in _notes )
				{
					if ( ! note.hasEventListener( SequencerEvent.SAMPLE_CHANGE ) )
					{
						note.addEventListener( SequencerEvent.SAMPLE_CHANGE, calculateLength );
					}
					
					if ( ! note.source.hasEventListener( Event.CHANGE ) )
					{
						note.source.addEventListener( Event.CHANGE, calculateLength );
					}
				}
				
				calculateLength( new SequencerEvent( SequencerEvent.SAMPLE_CHANGE ) );
			}
		}
		
		public function add( note : Note ) : void
		{
			//Если это AudioLoop, то указываем глобальный bpm
			var loop : AudioLoop = note.source as AudioLoop;
			
			if ( loop )
			{
				loop.bpm = _bpm;
			}	
			
			_notes.push( note );
			
			if ( ! _ignoreChanges )
			{
				note.addEventListener( SequencerEvent.SAMPLE_CHANGE, calculateLength );
				note.source.addEventListener( Event.CHANGE, calculateLength );
				
				calculateLength( new SequencerEvent( SequencerEvent.SAMPLE_CHANGE ) );	
			}
		}
		
		public function remove( note : Note ) : void
		{
		  if ( note.hasEventListener( SequencerEvent.SAMPLE_CHANGE ) )
		  {
			  note.removeEventListener( SequencerEvent.SAMPLE_CHANGE, calculateLength ); 
		  }
			
          if ( note.hasEventListener( Event.CHANGE ) )
		  {
			  note.source.removeEventListener( Event.CHANGE, calculateLength ); 
		  }
		  
		  
		  note.source.dispose();
		  	
		  var i : int = 0;
		  
		  while( i < _notes.length )
		  {  
			  if ( _notes[ i ] == note )
			  {
				  _notes.splice( i, 1 );  
				  
				  break;
			  }  
			  
			  i ++;
		  }
		  
		  if ( ! ignoreChanges )
		  {
			  calculateLength( new SequencerEvent( SequencerEvent.SAMPLE_CHANGE ) );  
		  }
		}
		
		public function getRange(start:Number, end:Number):Vector.<Note>
		{
			var result : Vector.<Note> = new Vector.<Note>(); 
			var note   : Note;
			var i : int = 0;
			
			while( i < _notes.length )
			{
				note = _notes[ i ];
				
				if ( ( note.start < end ) && ( start < note.end ) )
				{
					if ( note.source && ! note.source.locked )
					{
						result.push( note );
					}	
				}
				
				i ++;
			}
			
			return result;
		}
		
		public function get start() : Number
		{
			return _start;
		}
		
		public function get end() : Number
		{
			return _end;
		}	
		
		public function calculateLength( e : Event = null ) : void
		{
			if ( ! _calculateLength ) 
			{
				return;
			}	
			
			_start = Number.MAX_VALUE;
			_end = 0.0;
			
			for each( var note : Note in _notes )
			{
				/*if ( ! note.source.locked )
				{*/
					_start = Math.min( _start, note.start );
					_end   = Math.max( note.end, _end );
				//}	
			}
			
			if ( _start == Number.MAX_VALUE )
			{
				_start = 0.0;
			}	
			
			if ( e )
			{
				dispatchEvent( new SequencerEvent( SequencerEvent.SAMPLE_CHANGE ) );
			}
		}
		
		public function serializeToXML() : String
		{	
			var str : String = '';
			
			str += '<notes>';
			 
			 for each ( var s : IXMLSerializable in _notes )
			  str += s.serializeToXML();
			
			str += '</notes>';
			
			return str;
		}
	}
}