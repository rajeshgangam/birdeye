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
 
package birdeye.vis.elements.geometry
{
	import adobe.utils.CustomActions;
	
	import com.degrafa.IGeometry;
	import com.degrafa.geometry.Line;
	import com.degrafa.paint.SolidStroke;
	
	import flash.geom.Rectangle;
	
	import mx.collections.CursorBookmark;
	
	import birdeye.vis.scales.*;
	import birdeye.vis.elements.collision.*;
	import birdeye.vis.data.DataItemLayout;
	import birdeye.vis.interfaces.INumerableScale;
	import birdeye.vis.guides.renderers.RasterRenderer;
	import birdeye.vis.guides.renderers.RectangleRenderer;

	public class ColumnElement extends StackElement 
	{
		override public function get elementType():String
		{
			return "column";
		}

		private var _baseAtZero:Boolean = true;
		[Inspectable(enumeration="true,false")]
		public function set baseAtZero(val:Boolean):void
		{
			_baseAtZero = val;
			invalidateProperties();
			invalidateDisplayList();
		}
		public function get baseAtZero():Boolean
		{
			return _baseAtZero;
		}
		
		private var _form:String;
		public function set form(val:String):void
		{
			_form = val;
			invalidateDisplayList();
		}

		public function ColumnElement()
		{
			super();
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			if (!itemRenderer)
				itemRenderer = RectangleRenderer;

			if (stackType == STACKED100 && cursor)
			{
				if (yScale)
				{
					if (yScale is INumerableScale)
						INumerableScale(yScale).max = maxYValue;
				} else {
					if (chart && chart.yScale && chart.yScale is INumerableScale)
						INumerableScale(chart.yScale).max = maxYValue;
				}
			}
		}

		private var poly:IGeometry;
		/** @Private 
		 * Called by super.updateDisplayList when the element is ready for layout.*/
		override protected function drawElement():void
		{
//			var renderer:ISeriesDataRenderer = new itemRenderer();
			
			var dataFields:Array = [];
			// prepare data for a standard tooltip message in case the user
			// has not set a dataTipFunction
			dataFields[0] = xField;
			dataFields[1] = yField;
			if (zField) 
				dataFields[2] = zField;

			var xPos:Number, yPos:Number, zPos:Number = NaN;
			var j:Object;
			
			var ttShapes:Array;
			var ttXoffset:Number = NaN, ttYoffset:Number = NaN;
			
			var y0:Number = getYMinPosition();
			var size:Number = NaN, colWidth:Number = 0; 

			gg = new DataItemLayout();
			gg.target = this;
			graphicsCollection.addItem(gg);

			cursor.seek(CursorBookmark.FIRST);

			while (!cursor.afterLast)
			{
				if (xScale)
				{
					xPos = xScale.getPosition(cursor.current[xField]);

					if (isNaN(size))
						size = xScale.interval*deltaSize;
				} else if (chart.xScale) {
					xPos = chart.xScale.getPosition(cursor.current[xField]);

					if (isNaN(size))
						size = chart.xScale.interval*deltaSize;
				}
				
				j = cursor.current[xField];
				if (yScale)
				{
					
					if (_stackType == STACKED100)
					{
						y0 = yScale.getPosition(baseValues[j]);
						yPos = yScale.getPosition(
							baseValues[j] + Math.max(0,cursor.current[yField]));
					} else {
						yPos = yScale.getPosition(cursor.current[yField]);
					}
				} else if (chart.yScale) {
					if (_stackType == STACKED100)
					{
						y0 = chart.yScale.getPosition(baseValues[j]);
						yPos = chart.yScale.getPosition(
							baseValues[j] + Math.max(0,cursor.current[yField]));
					} else 
						yPos = chart.yScale.getPosition(cursor.current[yField]);
				}
				
				switch (_stackType)
				{
					case OVERLAID:
						colWidth = size;
						xPos = xPos - size/2;
						break;
					case STACKED100:
						colWidth = size;
						xPos = xPos - size/2;
						ttShapes = [];
						ttXoffset = -30;
						ttYoffset = 20;
						if (chart.customTooltTipFunction == null)
						{
							var line:Line = new Line(xPos+ colWidth/2, yPos, xPos + colWidth/2 + ttXoffset/3, yPos + ttYoffset);
							line.stroke = new SolidStroke(0xaaaaaa,1,2);
			 				ttShapes[0] = line;
						}
						break;
					case STACKED:
						xPos = xPos + size/2 - size/_total * _stackPosition;
						colWidth = size/_total;
						break;
				}
				
				var yAxisRelativeValue:Number = NaN;

				// TODO: fix stacked100 on 3D
				if (zScale)
				{
					zPos = zScale.getPosition(cursor.current[zField]);
					yAxisRelativeValue = XYZ(zScale).height - zPos;
				} else if (chart.zAxis) {
					zPos = chart.zAxis.getPosition(cursor.current[zField]);
					// since there is no method yet to draw a real z axis 
					// we create an y axis and rotate it to properly visualize 
					// a 'fake' z axis. however zPos over this y axis corresponds to 
					// the axis height - zPos, because the y axis in Flex is 
					// up side down. this trick allows to visualize the y axis as
					// if it would be a z. when there will be a 3d line class, it will 
					// be replaced
					yAxisRelativeValue = XYZ(chart.zAxis).height - zPos;
				}

 				var bounds:Rectangle = new Rectangle(xPos, yPos, colWidth, y0 - yPos);

				// yAxisRelativeValue is sent instead of zPos, so that the axis pointer is properly
				// positioned in the 'fake' z axis, which corresponds to a real y axis rotated by 90 degrees
				createTTGG(cursor.current, dataFields, xPos + colWidth/2, yPos, yAxisRelativeValue, 3,ttShapes,ttXoffset,ttYoffset);

				if (zField)
				{
					if (!isNaN(zPos))
					{
						gg = new DataItemLayout();
						gg.target = this;
						graphicsCollection.addItem(gg);
						ttGG.posZ = ttGG.z = gg.posZ = gg.z = zPos;
					} else
						zPos = 0;
				}

				if (ttGG && _extendMouseEvents)
					gg = ttGG;
				
//				poly = renderer.getGeometry(bounds);

 				if (_source)
					poly = new RasterRenderer(bounds, _source);
 				else 
					poly = new itemRenderer(bounds);

				poly.fill = fill;
				poly.stroke = stroke;
				gg.geometryCollection.addItemAt(poly,0);

				if (_showItemRenderer)
				{
					var shape:IGeometry = new itemRenderer(bounds);
					shape.fill = fill;
					shape.stroke = stroke;
					gg.geometryCollection.addItem(shape);
				}

				cursor.moveNext();
			}

			if (zField)
				zSort();
		}
		
/* 		private function getXMinPosition():Number
		{
			var xPos:Number;
			
			if (xAxis)
			{
				if (xAxis is NumericAxis)
					xPos = xAxis.getPosition(minXValue);
			} else {
				if (chart.xAxis is NumericAxis)
					xPos = chart.xAxis.getPosition(minXValue);
			}
			
			return xPos;
		}
 */		
		private function getYMinPosition():Number
		{
			var yPos:Number;
			if (yScale && yScale is INumerableScale)
			{
				if (_baseAtZero)
					yPos = yScale.getPosition(0);
				else
					yPos = yScale.getPosition(INumerableScale(yScale).min);
			} else {
				if (chart.yScale is INumerableScale)
				{
					if (_baseAtZero)
						yPos = chart.yScale.getPosition(0);
					else
						yPos = chart.yScale.getPosition(INumerableScale(chart.yScale).min);
				}
			}
			return yPos;
		}
	}
}