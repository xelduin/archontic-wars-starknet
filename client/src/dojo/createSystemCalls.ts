import { Account } from "starknet";
import {
  Entity,
  Has,
  HasValue,
  World,
  defineSystem,
  getComponentValue,
} from "@dojoengine/recs";
import { uuid } from "@latticexyz/utils";
import { ClientComponents } from "./createClientComponents";
import { getEntityIdFromKeys } from "@dojoengine/utils";
import type { IWorld } from "./typescript/contracts.gen";
import { Direction } from "./typescript/models.gen";

export type SystemCalls = ReturnType<typeof createSystemCalls>;

export function createSystemCalls(
  { client }: { client: IWorld },
  { Position, Moves }: ClientComponents,
  world: World
) {
  const spawn = async (account: Account) => {
    const entityId = getEntityIdFromKeys([BigInt(account.address)]) as Entity;

    const positionId = uuid();
    Position.addOverride(positionId, {
      entity: entityId,
      value: {
        player: BigInt(entityId),
        vec: {
          x: 10 + (getComponentValue(Position, entityId)?.vec.x || 0),
          y: 10 + (getComponentValue(Position, entityId)?.vec.y || 0),
        },
      },
    });

    try {
      await client.formations.spawn({
        account,
      });

      // Wait for the indexer to update the entity
      // By doing this we keep the optimistic UI in sync with the actual state
      await new Promise<void>((resolve) => {
        defineSystem(
          world,
          [
            Has(Position),
            HasValue(Position, { player: BigInt(account.address) }),
          ],
          () => {
            resolve();
          }
        );
      });
    } catch (e) {
      console.log(e);
      Position.removeOverride(positionId);
    } finally {
      Position.removeOverride(positionId);
    }
  };

  const move = async (account: Account, direction: Direction) => {
    try {
      await client.actions.move({
        account,
        direction,
      });

      // Wait for the indexer to update the entity
      // By doing this we keep the optimistic UI in sync with the actual state
      await new Promise<void>((resolve) => {
        defineSystem(
          world,
          [Has(Moves), HasValue(Moves, { player: BigInt(account.address) })],
          () => {
            resolve();
          }
        );
      });
    } catch (e) {
      console.log(e);
    }
  };

  return {
    spawn,
    move,
  };
}
