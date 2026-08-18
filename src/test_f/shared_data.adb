-- shared_data.adb
package body Shared_Data is
   protected body Counter is
      procedure Set (V : Integer) is
      begin
         Value := V;
      end Set;
      function Get return Integer is
      begin
         return Value;
      end Get;
   end Counter;
end Shared_Data;