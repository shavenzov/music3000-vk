package com.audioengine.format.tasks
{
	import com.thread.BaseRunnable;
	
	import flash.events.Event;
	import flash.utils.ByteArray;
	
	public class ProcessingStack extends BaseRunnable implements IEncoder
	{
		/**
		 * Список выполняемых поочередно действий 
		 */		
		private const stack : Vector.<IEncoder> = new Vector.<IEncoder>();
		
		/**
		 * Входные данные 
		 */		
		private var _rawData : ByteArray;
		
		/**
		 * Выходные данные 
		 */		
		private var _outputData : ByteArray;
		
		/**
		 * Текущий выполняемый процесс 
		 */		
		private var current : IEncoder;
		
		/**
		 * Неизменный прогресс выполненных действий 
		 */		
		private var balance : int = 0;
		
		/**
		 * Текущий статус 
		 */		
		private var _status : int = EncoderStatus.NONE;
		
		/**
		 * Параметры для измерения времени до завершения операции 
		 * 
		 */
		/*
		private var _lastProgress : int;
		private var _lastTime     : Number;
		private var _remainTime   : Number;
		*/
		
		public function ProcessingStack()
		{
			super();
		}
		
		public function clear() : void
		{
			var i : int = 0;
			
			if ( current )
			{
				current.clear();
				current = null;
			}
			
			while( i < stack.length )
			{
				stack[ i ].clear();
				stack[ i ] = null;
				
				i ++;
			}
			
			stack.length = 0;
			
			if ( _rawData )
			{
				_rawData.clear();
				_rawData = null;
			}
			
			if ( _outputData )
			{
				_outputData.clear();
				_outputData = null;
			}
		}
		
		public function get rawData() : ByteArray
		{
			return _rawData;
		}
		
		public function set rawData( value : ByteArray ) : void
		{
			_rawData = value;
			_total = calcTotal( _rawData.length );
		}
		
		public function get outputData() : ByteArray
		{
			return _outputData;
		}
		
		public function get status() : int
		{
			return _status;
		}
		
		public function get statusString() : String
		{
		  if ( current )
		  {
			  return current.statusString;  
		  }
		  
		  if ( _status == EncoderStatus.NONE )
		  {
			  return 'Ожидание';
		  }
		  
		  if ( _status == EncoderStatus.DONE )
		  {
			  return 'Готово';
		  }
		  
		  return null;
		}
		
		public function add( encoder : IEncoder ) : void
		{
			stack.push( encoder );
		}
		
		public function calcTotal( rawDataLength : int ) : int
		{
			_total = 0;
			
			for each( var encoder : IEncoder in stack )
			{
				_total += encoder.calcTotal( rawDataLength );
			}
			
			return _total;
		}
		
		private function onStatusChange( e : Event ) : void
		{
			dispatchEvent( e );
		}
		
		private function getNext() : IEncoder
		{
			var encoder : IEncoder = stack.shift();
			    encoder.rawData = _rawData;
				
			return encoder;
		}
		
		private function remove( encoder : IEncoder ) : void
		{
			encoder.clear();
		}
		
		private function changeStatus( newStatus : int ) : void
		{
			if ( _status != newStatus )
			{
				_status = newStatus;
				
				if ( current && current.hasEventListener( Event.CHANGE ) )
					current.dispatchEvent( new Event( Event.CHANGE ) );
				
				if ( hasEventListener( Event.CHANGE ) )
					dispatchEvent( new Event( Event.CHANGE ) );
			}
		}
		/*
		private function calculateRemainTime() : void
		{
			if ( ! isNaN( _lastTime ) )
			{
				var time      : Number = getTimer() - _lastTime;
				var iteration : int    = _progress - _lastProgress;
				var speed     : Number = ( 1000 * iteration ) / time; //Итераций в секунду 
				
				_remainTime = ( _total - _progress ) / speed;
			}
			
			_lastProgress = _progress;
			_lastTime     = getTimer();
			
			trace( _remainTime, 'c', speed );
		}
		*/
		override public function process():void
		{
			if ( ( _status == EncoderStatus.DONE ) || ( error ) )
			{
				return;
			}
			
			if ( ! current )
			{
				current = getNext();
			}
			
			current.process();
			
			if ( current.status != EncoderStatus.DONE ) 
			{
			 	changeStatus( current.status );
			}
			
			if ( current.error )
			{
				error = true;
				return;
			}
			
			_progress = balance + current.progress;
			
			//trace( 'progress', _progress, _total );
			
			if ( current.completed )
			{
				balance += current.total;
				_rawData = current.outputData;
				_rawData.position = 0;
				
				remove( current );
				current = null;
				
				if ( stack.length == 0 )
				{
					_outputData = _rawData;
					changeStatus( EncoderStatus.DONE );
				}
				else
				{
					current = getNext();
				}
			}
		}
	}
}