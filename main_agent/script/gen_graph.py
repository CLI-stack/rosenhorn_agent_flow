import networkx as nx
import argparse
import re
import gzip

parser = argparse.ArgumentParser(description='Update task csv item')
parser.add_argument('--f',type=str, default = "tile.gh",required=True,help="tile graph file")
parser.add_argument('--node',type=str, default = "node",required=False,help="node")
parser.add_argument('--full',type=int, default = "1",required=True,help="analyze all port")
args = parser.parse_args()


def find_longest_path(graph, target_node):
    # Initialize variables to keep track of the longest path
    longest_path = []
    longest_length = 0

    # Helper function to perform DFS and find paths
    def dfs(current_node, path):
        nonlocal longest_path, longest_length
        path.append(current_node)

        # If the current node is the target node, check if the path is the longest
        if current_node == target_node:
            if len(path) > longest_length:
                longest_path = path.copy()
                longest_length = len(path)

        # Explore neighbors
        for neighbor in graph.neighbors(current_node):
            if neighbor not in path:  # Avoid cycles
                dfs(neighbor, path)

        # Backtrack
        path.pop()

    # Start DFS from each node
    for node in graph.nodes:
        dfs(node, [])

    return longest_path

# Example usage
#G = nx.DiGraph()
#G.add_edges_from([(1, 2), (2, 3), (3, 4), (1, 5), (5, 6), (6, 4)])

#target_node = 4
#longest_path = find_longest_path(G, target_node)

def get_downstream_nodes(graph, start_node, max_nodes=1000):
    # Initialize a list to store downstream nodes
    downstream_nodes = []

    # Use a BFS approach to explore the graph
    for node in nx.bfs_tree(graph, start_node):
        if node != start_node:  # Exclude the start node itself
            downstream_nodes.append(node)
        if len(downstream_nodes) >= max_nodes:
            break

    return downstream_nodes

# Function to find end nodes from a specific node
def find_end_nodes(graph, start_node):
    end_nodes = []
    for node in nx.dfs_postorder_nodes(graph, start_node):
        if graph.out_degree(node) == 0:  # No outgoing edges
            end_nodes.append(node)
    return end_nodes

# Find end nodes starting from node 'A'
# end_nodes = find_end_nodes(G, 'A')
# print("End nodes:", end_nodes)

# Function to find the start node of a specific node
def find_start_node(graph, target_node):
    # Perform a reverse BFS from the target node
    predecessors = nx.bfs_predecessors(graph.reverse(), target_node)
    
    # Convert predecessors to a dictionary
    pred_dict = dict(predecessors)
    
    # Find the start node (node with no predecessor)
    current_node = target_node
    while current_node in pred_dict:
        current_node = pred_dict[current_node]
    
    return current_node

# Find the start node
# start_node = find_start_node(G, target_node)
# print(f"The start node for {target_node} is {start_node}")


# Create an empty undirected graph
G = nx.DiGraph()
node_h =  {}
if args.full == 1:
    node = ""
else:
    node = args.node
inport_h = {}
inport_feed_h = {}
outport_h = {}
#o = open(args.f+".log",'w')
#o.write('\n')
#o.close()

with gzip.open(args.f,'rb') as f:
    print("# Start build graph:")
    for line in f.readlines():
        line = line.decode().strip('\n')
        if len(line.split()) == 2:
            driver = line.split()[0]
            load = line.split()[1]

            if re.search("_inport",driver):
                if re.search("FE_FEEDX",driver):
                    inport_feed_h[driver] = 1
                else:
                    inport_h[driver] = 1
            if re.search("_outport",load):
                outport_h[load] = 1
            if driver in node_h and load in node_h:
                G.add_edge(driver, load)
            elif driver in node_h:
                G.add_node(load)
                G.add_edge(driver, load)
                node_h[load] = 1
            elif load in node_h:
                G.add_node(driver)
                G.add_edge(driver, load)
                node_h[driver] = 1
            else:
                G.add_node(driver)
                G.add_node(load)
                G.add_edge(driver, load)
                node_h[driver] = 1
                node_h[load] = 1
f.close()
num_nodes = G.number_of_nodes()
print(f"Number of nodes: {num_nodes}")

# Get the number of edges
num_edges = G.number_of_edges()
print(f"Number of edges: {num_edges}")
if re.search("\S",node):
    print("# check node",node)
    child_nodes = list(nx.algorithms.descendants(G, node))
    print("# child nodes:",len(child_nodes))
    for nd in child_nodes:
        #print(nd)
        if re.search("inport|outport",nd):
            print(nd)
    parents = list(nx.ancestors(G, node))
    print("# parent nodes:",len(parents))
    for nd in parents:
        if re.search("inport|outport",nd):
            print(nd)
bus_h = {}
for inport in inport_h:
    se = re.search("\[(\S+)\]",inport)
    if se:
        bit = int(se.group(1))
        bus = re.sub("\[.*\]","",inport)
        if bus in bus_h:
            if bus_h[bus] < bit:
                bus_h[bus] = bit
        else:
            bus_h[bus] = bit
    else:
        bus = inport
        bus_h[bus] = 1
        
if args.full == 1:
    n_inport = 0
    for inport in inport_h:
        n_inport = n_inport + 1
        se = re.search("\[(\S+)\]",inport)
        if se:
            bit = int(se.group(1))
            bus = re.sub("\[.*\]","",inport)
            if bus in bus_h:
                if bit < bus_h[bus]:
                    continue
                if bit < 64:
                    continue
        else:
            continue
        if re.search("FE_FEEDX",inport):
            continue
        n_outport = 0
        child_nodes = list(nx.algorithms.descendants(G, inport))
        outports = [word for word in child_nodes if "_outport" in word]
        child_nodes = get_downstream_nodes(G, inport, max_nodes=3000)
        nodes_with_more_than_5_edges = [nd for nd in child_nodes if G.degree(nd) > 7]
        """
        print("# Start print node")
        for nd in nodes_with_more_than_5_edges:
            print(nd)
        if n_inport == 5:
            break
        """
        print(n_inport," of ",len(inport_h),len(inport_feed_h),inport,len(outports),len(nodes_with_more_than_5_edges))
        #o.write(str(n_inport)+" of "+str(len(inport_h))+" " + inport+" "+str(len(outports))+'\n')
        n_inport = n_inport + 1

if re.search("\S",args.node):
    start_node = args.node
    shortest_paths = nx.single_source_shortest_path(G, args.node)

    # Print the shortest paths
    final_path = [] 
    print("# Print end nodes")
    node_file = re.sub("\/","_",node)
    node_file = re.sub("\[|\]","_",node_file)
    ndf = open(node_file+".node.tcl",'w')

    edl = open("end_nodes.tcl",'w')
    i = 0
    
    for target_node, path in shortest_paths.items():
        if re.search("outport"," ".join(path)):
            edl.write("set path("+ str(i)+ ") " + "{" + re.sub("_outport",""," ".join(path))+ "}" + '\n')
            ndf.write("set path("+ str(i)+ ") " + "{" + re.sub("_outport",""," ".join(path))+ "}" + '\n')
            i = i + 1
    edl.close()
    # Find shortest paths from all nodes to the target node
    print("# Print start nodes")
    shortest_paths = {}
    for node in inport_h:
        try:
            path = nx.shortest_path(G, source=node, target=args.node)
            shortest_paths[node] = path
        except nx.NetworkXNoPath:
            # If there's no path from the node to the target, skip it
            pass

    # Print the shortest paths
    sdl = open("start_nodes.tcl",'w')
    for start_node, path in shortest_paths.items():
        if re.search("inport"," ".join(path)):
            sdl.write("set path("+ str(i) + ") " + "{" +re.sub("_inport",""," ".join(path)) + "}" +'\n')
            ndf.write("set path("+ str(i) + ") " + "{" +re.sub("_inport",""," ".join(path)) + "}" +'\n')
            i = i + 1
    sdl.close()
    ndf.close()
    #start_nodes = find_start_node(G,args.node)
    #print("# Print start nodes")
    #print(start_nodes)
    
#o.close()

