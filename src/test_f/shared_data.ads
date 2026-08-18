package Shared_Data is
   protected Counter is
      procedure Set (V : Integer);
      function  Get return Integer;
   private
      Value : Integer := 0;
   end Counter;
end Shared_Data;