package mx.managers.history
{
	public class HistoryRecord
	{
		/**
		 * Операция для действия назад 
		 */		
		public var back : Vector.<HistoryOperation>;
		
		/**
		 * Операция для действия вперед 
		 */		
		public var forward : Vector.<HistoryOperation>;
		
		private var _backName    : String;
		private var _forwardName : String;
		
		public function HistoryRecord( back : *, forward : *, _backName : String = null, _forwardName : String = null )
		{
			
		  if ( back as HistoryOperation )
		  {	  
			  this.back = Vector.<HistoryOperation>( [ back ] );
		  }
		  else
		  {	  
			  this.back    = back; 
		  }
			
		  if ( forward as HistoryOperation )
		  {
			  this.forward = Vector.<HistoryOperation>( [ forward ] );
		  }	  
		  else
		  {
			  this.forward = forward;
		  }
		  
		  this._backName    = _backName;
		  this._forwardName = _forwardName;
		}
		
		/**
		 * Добавляет дополнительные события 
		 * @param back    - HistoryOperation или Vector.<HistoryOperation>
		 * @param forward - HistoryOperation или Vector.<HistoryOperation>
		 * @return 
		 * 
		 */		
		public function add( back : *, forward : * ) : void
		{
			if ( back )
			{	
				if ( back as HistoryOperation )
				{	  
					this.back.push( back );
				}
				else
				{	  
					this.back = this.back.concat( back ); 
				}
			}
			
			if ( forward )
			{
				if ( forward as HistoryOperation )
				{
					this.forward.push( forward );
				}	  
				else
				{
					this.forward = this.forward.concat( forward );
				}
			}	
		}
		/*
		private static function swap( list : Vector.<HistoryOperation>, index1 : int, index2 : int ) : void
		{
			var b : HistoryOperation = list[ index1 ];
			list[ index1 ] = list[ index2 ];
			list[ index2 ] = b;
		}	
		*/
		/**
		 * Меняет местами действия в масиве "Назад" 
		 * @param index1
		 * @param index2
		 * 
		 */		
		/*public function swapBack( index1 : int, index2 : int ) : void
		{
			swap( back, index1, index2 );
		}
		*/
		/**
		 * Меняет местами действия в масиве "Вперед" 
		 * @param index1
		 * @param index2
		 * 
		 */		
		/*public function swapForward( index1 : int, index2 : int ) : void
		{
			swap( forward, index1, index2 );
		}	
		*/
		/**
		 * Выполняет необходжимые действия для перехода на одно действие назад 
		 * 
		 */		
		public function goBack() : void
		{	
			for each( var o : HistoryOperation in back )
			{
				o.call();
			}	
		}
		
		/**
		 * Выполняет необходимые действия для перехода на одно действия вперед 
		 * 
		 */		
		public function goForward() : void
		{	
			for each( var o : HistoryOperation in forward )
			{
				o.call();
			}
		}
		/*
		private static function getName( obj : Vector.<HistoryOperation> ) : String
		{	
			var i : int = 0;
			var str : String = '';
			
			while( i < obj.length )
			{
				str += obj[ i ].name;
				
				i ++;
				
				if ( obj.length < i )
				{
					str += '\n';
				}	
			}
			
			return str;
		}
		*/
		/**
		 * Возвращает имя совершенного действия "Назад" 
		 * @return 
		 * 
		 */		
		public function get backName() : String
		{	
			return _backName/* ? _backName : getName( back )*/;
		}
		
		public function set backName( value : String ) : void
		{
			_backName = value;
		}
		
		/**
		 * Возвращает имя совершенного действия "Вперед" 
		 * @return 
		 * 
		 */		
		public function get forwardName() : String
		{	
			return _forwardName/* ? _forwardName : getName( forward )*/;
		}
		
		public function set forwardName( value : String ) : void
		{
			_forwardName = value;
		}
	}
}