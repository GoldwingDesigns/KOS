clearVecDraws().
      function drawBox{
        local edges is LIST().
        for edge in edges { set edge:show to false. }
        wait 0.

        // These need to calculate using relative coords to find all the box edges:
        local rn to B:relmin:normalized * (B:relmin:mag + buffer).
        local rx to B:relmax:normalized * (B:relmax:mag + buffer).
        local rel_x_size is rx:X - rn:X.
        local rel_y_size is rx:Y - rn:Y.
        local rel_z_size is rx:Z - rn:Z.

        edges:CLEAR().

        // The 4 edges parallel to the relative X axis:
        edges:ADD(Vecdraw(
          {return B:ABSORIGIN + B:FACING * V(rn:X, rn:Y, rn:Z).},
          {return B:FACING * V(rel_x_size, 0, 0).},
          RGBA(1,0,1,0.75), "", 1, true, 0.02, false, false)).
        edges:ADD(Vecdraw(
          {return B:ABSORIGIN + B:FACING * V(rn:X, rn:Y, rx:Z).},
          {return B:FACING * V(rel_x_size, 0, 0).},
          RGBA(1,0,1,0.75), "", 1, true, 0.02, false, false)).
        edges:ADD(Vecdraw(
          {return B:ABSORIGIN + B:FACING * V(rn:X, rx:Y, rx:Z).},
          {return B:FACING * V(rel_x_size, 0, 0).},
          RGBA(1,0,1,0.75), "", 1, true, 0.02, false, false)).
        edges:ADD(Vecdraw(
          {return B:ABSORIGIN + B:FACING * V(rn:X, rx:Y, rn:Z).},
          {return B:FACING * V(rel_x_size, 0, 0).},
          RGBA(1,0,1,0.75), "", 1, true, 0.02, false, false)).

        // The 4 edges parallel to the relative Y axis:
        edges:ADD(Vecdraw(
          {return B:ABSORIGIN + B:FACING * V(rn:X, rn:Y, rn:Z).},
          {return B:FACING * V(0, rel_y_size, 0).},
          RGBA(1,0,1,0.75), "", 1, true, 0.02, false, false)).
        edges:ADD(Vecdraw(
          {return B:ABSORIGIN + B:FACING * V(rn:X, rn:Y, rx:Z).},
          {return B:FACING * V(0, rel_y_size, 0).},
          RGBA(1,0,1,0.75), "", 1, true, 0.02, false, false)).
        edges:ADD(Vecdraw(
          {return B:ABSORIGIN + B:FACING * V(rx:X, rn:Y, rx:Z).},
          {return B:FACING * V(0, rel_y_size, 0).},
          RGBA(1,0,1,0.75), "", 1, true, 0.02, false, false)).
        edges:ADD(Vecdraw(
          {return B:ABSORIGIN + B:FACING * V(rx:X, rn:Y, rn:Z).},
          {return B:FACING * V(0, rel_y_size, 0).},
          RGBA(1,0,1,0.75), "", 1, true, 0.02, false, false)).

        // The 4 edges parallel to the relative Z axis:
        edges:ADD(Vecdraw(
          {return B:ABSORIGIN + B:FACING * V(rn:X, rn:Y, rn:Z).},
          {return B:FACING * V(0, 0, rel_z_size).},
          RGBA(1,0,1,0.75), "", 1, true, 0.02, false, false)).
        edges:ADD(Vecdraw(
          {return B:ABSORIGIN + B:FACING * V(rn:X, rx:Y, rn:Z).},
          {return B:FACING * V(0, 0, rel_z_size).},
          RGBA(1,0,1,0.75), "", 1, true, 0.02, false, false)).
        edges:ADD(Vecdraw(
          {return B:ABSORIGIN + B:FACING * V(rx:X, rx:Y, rn:Z).},
          {return B:FACING * V(0, 0, rel_z_size).},
          RGBA(1,0,1,0.75), "", 1, true, 0.02, false, false)).
        edges:ADD(Vecdraw(
          {return B:ABSORIGIN + B:FACING * V(rx:X, rn:Y, rn:Z).},
          {return B:FACING * V(0, 0, rel_z_size).},
          RGBA(1,0,1,0.75), "", 1, true, 0.02, false, false)).
      }
      function drawArrows{
        local apointabs to apoint-tgt:ship:position.
        Vecdraw(
        {return tgt:nodeposition.},
        {return apointabs+tgt:ship:position-tgt:nodeposition.},
        green, "apprpoint", 1, true).
      }
      drawBox().
      drawArrows().