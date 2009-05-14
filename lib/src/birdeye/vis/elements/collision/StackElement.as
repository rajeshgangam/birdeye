/*  
 * The MIT License
 *
 * Copyright (c) 2008
 * United Nations Office at Geneva
 * Center for Advanced Visual Analytics
 * http://cava.unog.ch
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
 
package birdeye.vis.elements.collision
{
	import birdeye.vis.VisScene;
	import birdeye.vis.coords.Cartesian;
	import birdeye.vis.elements.BaseElement;
	import birdeye.vis.elements.geometry.*;
	import birdeye.vis.interfaces.IStack;
	import birdeye.vis.scales.*;
	
	import flash.events.Event;
	
	[Exclude(name="stackType", kind="property")] 
	[Exclude(name="total", kind="property")] 
	[Exclude(name="stackPosition", kind="property")] 
	[Exclude(name="elementType", kind="property")] 

	public class StackElement extends BaseElement implements IStack
	{
		protected var deltaSize:Number;
		
		public static const OVERLAID:String = "overlaid";
		public static const STACKED:String = "stacked";
		public static const STACKED100:String = "stacked100";
		
		protected var _stackType:String = OVERLAID;
		public function set stackType(val:String):void
		{
			_stackType = val;
			invalidateProperties();
			invalidateDisplayList();
		}
		public function get stackType():String
		{
			return _stackType;
		}
		
		public var _baseValues:Array;
		public function set baseValues(val:Array):void
		{
			_baseValues = val;
			invalidateProperties();
			invalidateDisplayList();
		}
		public function get baseValues():Array
		{
			return _baseValues;
		}

		protected var _total:Number = NaN;
		public function set total(val:Number):void
		{
			_total = val;
			invalidateProperties();
			invalidateDisplayList();
		}

		protected var _stackPosition:Number = NaN;
		public function set stackPosition(val:Number):void
		{
			_stackPosition = val;
			invalidateProperties();
			invalidateDisplayList();
		}
		
		public function get elementType():String
		{
			// to be overridden
			
			return null;
		}
		
		public function StackElement()
		{
			super();
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();

			if (chart is Cartesian && Cartesian(chart).is3D)
				deltaSize = 1/5;
			else 
				deltaSize = 3/5;
		}
		
		override protected function getMaxValue(field:String):Number
		{
			var max:Number = super.getMaxValue(field);
			if (chart && chart.coordType == VisScene.CARTESIAN && stackType == STACKED100) 
				max = Math.max(max, Cartesian(chart).maxStacked100);
				
			return max;
		}
	}
}