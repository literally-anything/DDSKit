#pragma once

#include "types.hpp"

namespace fastdds {
    void _statusMaskAdd(_StatusMask &mask1, _StatusMask mask2);
    void _statusMaskSubtract(_StatusMask &mask1, _StatusMask mask2);
}
