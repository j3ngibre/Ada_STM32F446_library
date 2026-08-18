
with Ada.Real_Time; use Ada.Real_Time;

package TaskPant is
   task Pintar_Task with
      Priority => 10,       -- prioridad estática obligatoria en Ravenscar
      Storage_Size => 1024; -- tamaño de pila explícito

end TaskPant;
