package com.audioengine.processors
{
	import com.audioengine.calculations.MixAndGain;
	import com.audioengine.core.IProcessor;
	import com.audioengine.sequencer.events.SequencerEvent;
	
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	
	public class Mixer extends EventDispatcher implements IProcessor
	{
		/**
		 * Список входов микшера 
		 */		
		private const _inputs    : Vector.<IProcessor> = new Vector.<IProcessor>();
		
		/**
		 * Данные для микширования 
		 */		
		private const _data   : Vector.<ByteArray> = new Vector.<ByteArray>();
		
		/**
		 * Нулевые данные 
		 */		
		private const zeroBytes: ByteArray = new ByteArray();
		
		/**
		 * PixelBender реализация вычислений микшера 
		 */		
		private const _mixer  : MixAndGain = new MixAndGain();
		
		/**
		 * Игнорировать изменения т.е. не отправлять событие при изменении параметров 
		 */		
		private var _ignoreChanges : Boolean;
		
		public function Mixer()
		{
		  _mixer.tracks = _data;
		}
		
		public function get ignoreChanges() : Boolean
		{
			return _ignoreChanges;
		}
		
		public function set ignoreChanges( value : Boolean ) : void
		{
			_ignoreChanges = value;
		}
		
		public function get enabledChannels() : int
		{
			return _mixer.enabledChannels;
		}
		
		public function get disabledChannels() : int
		{
			return _mixer.disabledChannels;
		}	
		
		public function getPanAt( channelNumber : uint ) : Number
		{
			return _mixer.getPan( channelNumber );
		}
		
		public function setPanAt( channelNumber : uint, pan : Number ) : void
		{
			_mixer.setPan( channelNumber, pan );
			
			if ( ! _ignoreChanges )
			dispatchEvent( new SequencerEvent( SequencerEvent.MIXER_PARAM_CHANGED ) );
		}
		
		public function getVolumeAt( channelNumber : uint ) : Number
		{
			return _mixer.getVolumeAt( channelNumber );
		}
		
		public function setVolumeAt( channelNumber : uint, volume : Number ) : void
		{
			_mixer.setVolumeAt( channelNumber, volume );
			
			if ( ! _ignoreChanges )
			dispatchEvent( new SequencerEvent( SequencerEvent.MIXER_PARAM_CHANGED ) )
		}
		
		public function getMonoAt( channelNumber : uint ) : Boolean
		{
			return _mixer.getMonoAt( channelNumber );
		}
		
		public function setMonoAt( channelNumber : uint, value : Boolean ) : void
		{
			_mixer.setMonoAt( channelNumber, value );
			
			if ( ! _ignoreChanges )
			dispatchEvent( new SequencerEvent( SequencerEvent.MIXER_PARAM_CHANGED ) )
		}
		
		public function get soloChannel() : int
		{
			return _mixer.soloChannel;
		}
		
		public function set soloChannel( trackNumber : int ) : void
		{	
			_mixer.soloChannel = trackNumber;
			
			if ( ! _ignoreChanges )
			dispatchEvent( new SequencerEvent( SequencerEvent.MIXER_PARAM_CHANGED ) )
		}
		
		public function get inputs() : Vector.<IProcessor>
		{
			return _inputs;
		}
		
		public function get numChannels() : int
		{
			return _inputs.length;
		}	
		
		public function swapChannels( index1 : int, index2 : int ) : void
		{
			var d : IProcessor = _inputs[ index1 ];
			 _inputs[ index1 ] = _inputs[ index2 ];
			 _inputs[ index2 ] = d;
			
			_mixer.swapChannels( index1, index2 );
		}
		
		public function moveChannels( fromIndex : int, toIndex : int ) : void
		{
			var d : Vector.<IProcessor> = _inputs.splice( fromIndex, 1 );
			
			_inputs.splice( toIndex, 0, d[ 0 ] );
				
			_mixer.moveChannels( fromIndex, toIndex );
		}	
		
		public function add( device : IProcessor, channelNumber : int = -1 ) : void
		{
			if ( channelNumber == -1 )
			{
				channelNumber = _inputs.length;
			}	
			
			_inputs.splice( channelNumber, 0, device ); 
			_data.push( new ByteArray() );
			_mixer.addControlAt( channelNumber );
		}
		
		public function remove( channelNumber : uint = -1 ) : void
		{
			channelNumber = channelNumber == -1 ? _inputs.length - 1 : channelNumber;
			
			_inputs.splice( channelNumber, 1 );
			_data.splice( channelNumber, 1 );
			_mixer.removeControlAt( channelNumber );
		}	
		
		public function render(data:ByteArray, bytes:uint):void
		{
		  if ( _inputs.length > 0 )
		  {
			var i : int = 0;
			
            while( i < _inputs.length )
			{
				_data[ i ].position = 0;
				_data[ i ].length = bytes;
				_inputs[ i ].render( _data[ i ], bytes );
				
				i ++;
			}
			
			//Вычисляем
			_mixer.bytesLength = bytes;
			_mixer.calculate( data );
			
		  }
		  else
		  {
			  zeroBytes.length = bytes;
			  data.writeBytes( zeroBytes );
		  }	  
		}
	}
}